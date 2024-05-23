import packageJson from "../package.json";
import { cac } from "cac";
import * as fs from "fs";
import * as path from "path";
import * as child_process from "child_process";
import * as compiler from "@vue/compiler-dom";
import type {
  CompilerError,
  SFCBlock,
  SFCStyleBlock,
  SFCScriptBlock,
} from "@vue/compiler-sfc";
import type { ElementNode } from "@vue/compiler-core";
import { toVleamGeneratedPath } from "./utils";

import { URI } from "vscode-uri";
import * as rpc from "vscode-jsonrpc/node.js";

const cli = cac("vleam");

function createBlock(node: ElementNode, source: string) {
  const type = node.tag;
  let { start, end } = node.loc;
  let content = "";
  if (node.children.length) {
    start = node.children[0].loc.start;
    end = node.children[node.children.length - 1].loc.end;
    content = source.slice(start.offset, end.offset);
  } else {
    const offset = node.loc.source.indexOf(`</`);
    if (offset > -1) {
      start = {
        line: start.line,
        column: start.column + offset,
        offset: start.offset + offset,
      };
    }
    end = Object.assign({}, start);
  }
  const loc = {
    source: content,
    start,
    end,
  };
  const attrs: Record<string, any> = {};
  const block: SFCBlock &
    Pick<SFCStyleBlock, "scoped" | "module"> &
    Pick<SFCScriptBlock, "setup"> = {
    type,
    content,
    loc,
    attrs,
  };
  node.props.forEach((p) => {
    if (p.type === compiler.NodeTypes.ATTRIBUTE) {
      attrs[p.name] = p.value ? p.value.content || true : true;
      if (p.name === "lang") {
        block.lang = p.value && p.value.content;
      } else if (p.name === "src") {
        block.src = p.value && p.value.content;
      } else if (type === "style") {
        if (p.name === "scoped") {
          block.scoped = true;
        } else if (p.name === "module") {
          block.module = attrs[p.name];
        }
      } else if (type === "script" && p.name === "setup") {
        block.setup = attrs.setup;
      }
    }
  });
  return block;
}

export function getGleamScriptBlock(source: string) {
  const errors: CompilerError[] = [];

  let resultBlock: SFCScriptBlock | null = null;

  const ast = compiler.parse(source, {
    // there are no components at SFC parsing level
    isNativeTag: () => true,
    // preserve all whitespaces
    isPreTag: () => true,
    parseMode: "sfc",
    onError: (e) => {
      errors.push(e);
    },
    comments: true,
  });

  ast.children.forEach((node) => {
    if (node.type !== compiler.NodeTypes.ELEMENT) {
      return;
    }

    if (node.tag === "script") {
      const scriptBlock = createBlock(node, source) as SFCScriptBlock;
      const isSetup = !!scriptBlock.attrs.setup;
      if (!isSetup && scriptBlock.lang === "gleam") {
        resultBlock = scriptBlock;
      }
    }
  });

  return { gleamScriptBlock: resultBlock as SFCScriptBlock | null, errors };
}

const gleamToVueUriMap: { [gleamPath: string]: string } = {};
const messageOffsetMap: { [messageIdOrUri: string | number]: number } = {};

async function transformIncomingMessage(message: rpc.Message) {
  const vueFileUriString = message?.params?.textDocument?.uri;
  if (vueFileUriString) {
    const vueFileUri = URI.parse(vueFileUriString);
    const vueFileContent = fs.readFileSync(vueFileUri.path, "utf-8");

    // Parse the Vue file
    const { gleamScriptBlock, errors } = getGleamScriptBlock(vueFileContent);

    if (gleamScriptBlock) {
      const gleamFilePath = await toVleamGeneratedPath(
        process.cwd(),
        vueFileUri.path,
      );

      fs.writeFileSync(gleamFilePath, gleamScriptBlock.content);

      const offset = gleamScriptBlock.loc.start.line;
      const idOrUri = message.id ?? vueFileUriString;
      messageOffsetMap[idOrUri] = offset - 1;

      const gleamFileUriString = URI.file(gleamFilePath).toString();
      gleamToVueUriMap[gleamFileUriString] = vueFileUriString;
      message.params.textDocument.uri = gleamFileUriString;
    }

    if (errors.length) {
      console.error(`Errors parsing Vue SFC: ${errors.join("\n")}\n`);
    }
  }

  return message;
}

async function transformOutgoingMessage(message: rpc.Message) {
  const gleamFileUriString = message?.params?.uri;
  if (gleamFileUriString) {
    const vueFileUriString =
      gleamToVueUriMap[gleamFileUriString] ?? gleamFileUriString;

    message.params.uri = vueFileUriString;

    const idOrUri = message.id ?? vueFileUriString;

    const offset = messageOffsetMap[idOrUri];
    const diagnostics =
      Array.isArray(message.params.diagnostics) && message.params.diagnostics;

    if (offset && diagnostics && diagnostics.length) {
      for (const diagnostic of diagnostics) {
        if (diagnostic.range.start) {
          diagnostic.range.start.line = diagnostic.range.start.line + offset;
        }

        if (diagnostic.range.end) {
          diagnostic.range.end.line = diagnostic.range.end.line + offset;
        }
      }
    }
  }

  return message;
}

cli.command("lsp").action(() => {
  try {
    const gleamLspProcess = child_process.spawn("gleam", ["lsp"], {
      shell: false,
    });

    gleamLspProcess.stderr.on("data", (data) => {
      console.error(`stderr: ${data}`);
    });

    const editorStreams = {
      reader: new rpc.StreamMessageReader(process.stdin),
      writer: new rpc.StreamMessageWriter(process.stdout),
    };

    editorStreams.reader.listen(async (data) => {
      const transformedMessage = await transformIncomingMessage(data);
      gleamLspStreams.writer.write(transformedMessage);
    });

    const gleamLspStreams = {
      reader: new rpc.StreamMessageReader(gleamLspProcess.stdout),
      writer: new rpc.StreamMessageWriter(gleamLspProcess.stdin),
    };

    gleamLspStreams.reader.listen(async (data) => {
      const transformedMessage = await transformOutgoingMessage(data);
      editorStreams.writer.write(transformedMessage);
    });

    // TODO: cleanup
  } catch (e) {
    console.error(e);
  }
});

cli
  .command(
    "format",
    "format gleam portion of Vue SFC. Currently only supports stdin",
  )
  .option("--stdin", "Accept input on stdin")
  .action((options) => {
    if (!options.stdin) {
      console.error("Formatting is only supported with the --stdin flag\n");
      return;
    }

    const vueFileContent = fs.readFileSync(process.stdin.fd, "utf-8");
    const { gleamScriptBlock, errors } = getGleamScriptBlock(vueFileContent);

    if (gleamScriptBlock) {
      const gleamFormatProcess = child_process.spawn(
        "gleam",
        ["format", "--stdin"],
        {
          shell: false,
        },
      );

      gleamFormatProcess.stdout.on("data", (data) => {
        const formattedVue = vueFileContent.replace(
          gleamScriptBlock.content,
          "\n" + data.toString(),
        );
        process.stdout.write(formattedVue);
      });
      gleamFormatProcess.stderr.pipe(process.stderr);
      gleamFormatProcess.stdin.write(gleamScriptBlock.content);
      gleamFormatProcess.stdin.destroy();
    } else {
      console.error("Unable to parse Vue SFC\n");
    }

    if (errors.length) {
      console.error(`Errors parsing Vue SFC: ${errors.join("\n")}\n`);
    }
  });

cli.help();

cli.version(packageJson.version);

cli.parse();
