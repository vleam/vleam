import * as child_process from "child_process";
import * as fs from "fs";

import { getGleamScriptBlock } from "./_utils";
import { GEN_DIR, toVleamGeneratedPath, toVueOriginalPath } from "../utils";

import { URI } from "vscode-uri";
import * as rpc from "vscode-jsonrpc/node.js";

export function countNewlines(str: string) {
  let count = 1;

  let newlineChar: null | string = null;

  let i = 0;
  for (; !newlineChar && i < str.length; i++) {
    if (str[i] === "\n" || str[i] === "\r") {
      count = count + 1;
      newlineChar = str[i];
    }
  }

  for (; i < str.length; i++) {
    if (str[i] === newlineChar) {
      count = count + 1;
    }
  }

  return count;
}

export function deepLineOffset(obj: any, offset: number) {
  if (!obj || typeof obj !== "object") {
    return obj;
  }

  if (Array.isArray(obj)) {
    return obj.map((item) => deepLineOffset(item, offset));
  }

  const newObj = {};
  for (const [key, value] of Object.entries(obj)) {
    if (key === "line" && typeof value === "number" && value + offset >= 0) {
      newObj[key] = value + offset;
    } else {
      newObj[key] = deepLineOffset(value, offset);
    }
  }

  return newObj;
}

const gleamToVueUriMap: { [gleamPath: string]: string } = {};
const messageLineNumberMap: { [messageIdOrUri: string | number]: number } = {};

async function transformIncomingMessage(message: rpc.Message) {
  const vueFileUriString = (message as any)?.params?.textDocument?.uri;

  let lineNumber: number | null = null;

  if (vueFileUriString) {
    // Parse the Vue file
    const vueFileUri = URI.parse(vueFileUriString);
    const vueFileContent = fs.readFileSync(vueFileUri.path, "utf-8");
    const { gleamScriptBlock, errors } = getGleamScriptBlock(vueFileContent);

    // If there's a Gleam block
    if (gleamScriptBlock) {
      const gleamFilePath = await toVleamGeneratedPath(
        process.cwd(),
        vueFileUri.path,
      );

      // Generate Gleam file
      fs.writeFileSync(
        gleamFilePath,
        gleamScriptBlock.content.replace(/^\n/, ""),
      );

      // Calculate Gleam block's line number
      const gleamScriptTagIndex = vueFileContent.search(
        /<.*script.*lang.*gleam/,
      );
      lineNumber = countNewlines(
        vueFileContent.substring(0, gleamScriptTagIndex),
      );

      // Cache line number by file path
      if (vueFileUriString) {
        messageLineNumberMap[vueFileUriString] = lineNumber;
      }

      // Cache line number by message id
      const messageId = (message as any).id;
      if (messageId) {
        messageLineNumberMap[messageId] = lineNumber;
      }

      const gleamFileUriString = URI.file(gleamFilePath).toString();
      gleamToVueUriMap[gleamFileUriString] = vueFileUriString;
      (message as any).params.textDocument.uri = gleamFileUriString;
    }

    if (errors.length) {
      // TODO: send errors to LSP client
      console.error(`Errors parsing Vue SFC: ${errors.join("\n")}\n`);
    }

    const textDocumentText = (message as any)?.params?.textDocument?.text;
    if (textDocumentText) {
      try {
        // Get Gleam block
        const { gleamScriptBlock, errors } =
          getGleamScriptBlock(textDocumentText);

        if (gleamScriptBlock && errors.length === 0) {
          // Use Gleam block as textDocument text
          (message as any).params.textDocument.text =
            gleamScriptBlock.content.replace(/^\n/, "");
        }
      } catch (_e) {}
    }

    if (Array.isArray((message as any).params?.contentChanges)) {
      // Transform each contentChange into just Gleam code
      (message as any).params.contentChanges = (
        message as any
      ).params.contentChanges
        .map((contentChange: { text: string }) => {
          try {
            // Get Gleam block
            const { gleamScriptBlock, errors } = getGleamScriptBlock(
              contentChange.text,
            );

            if (!gleamScriptBlock || errors.length > 0) {
              return null;
            }

            // Use Gleam block as contentChange text
            return { text: gleamScriptBlock.content.replace(/^\n/, "") };
          } catch (e) {
            return null;
          }
        })
        .filter((contentChange: null | { text: string }) => !!contentChange);
    }
  }

  // Offset all line numbers
  return lineNumber ? deepLineOffset(message, lineNumber * -1) : message;
}

async function getOrGuessVueOriginalUri(
  gleamFileUriString?: string,
): Promise<string | null> {
  if (!gleamFileUriString) {
    return null;
  }

  if (
    gleamFileUriString?.includes(GEN_DIR) &&
    !gleamToVueUriMap[gleamFileUriString]
  ) {
    const gleamFileUri = URI.parse(gleamFileUriString);

    const originalPath = await toVueOriginalPath(
      process.cwd(),
      gleamFileUri.path,
    );

    const originalUri = originalPath && URI.file(originalPath).toString();

    if (originalUri) {
      gleamToVueUriMap[gleamFileUriString] = originalUri;
    }
  }

  return gleamToVueUriMap[gleamFileUriString] ?? null;
}

async function transformOutgoingMessage(message: rpc.Message) {
  let uriOrId = (message as any).id;

  if (rpc.Message.isNotification(message) || rpc.Message.isRequest(message)) {
    const gleamFileUriString = (message.params as any)?.uri;
    const vueFileUriString = await getOrGuessVueOriginalUri(gleamFileUriString);

    // URI has precedence over id, in case the response is relevant to a file
    // different from the one in the request. For example, jump to definition.
    uriOrId = vueFileUriString || uriOrId;

    // revert to `.vue` original uri
    if (vueFileUriString) {
      (message as any).params.uri = vueFileUriString;
    }
  }

  // revert to `.vue` original uri in code action response
  if (rpc.Message.isResponse(message)) {
    if (Array.isArray(message.result)) {
      for (const r of message.result) {
        if (r?.edit?.changes) {
          for (const [key, value] of Object.entries(r.edit.changes)) {
            const vueFileUriString = await getOrGuessVueOriginalUri(key);
            if (vueFileUriString) {
              r.edit.changes[vueFileUriString] = value;
              delete r.edit.changes[key];
            }
          }
        }
      }
    } else if (typeof message.result === "object") {
      const gleamFileUriString = (message.result as any)?.uri;

      const vueFileUriString =
        await getOrGuessVueOriginalUri(gleamFileUriString);

      uriOrId = vueFileUriString || uriOrId;

      if (vueFileUriString) {
        (message.result as any).uri = vueFileUriString;
      }
    }
  }

  // Offset all line numbers
  const lineNumber = uriOrId && messageLineNumberMap[uriOrId];

  return lineNumber ? deepLineOffset(message, lineNumber) : message;
}

export default function action() {
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

      if (transformedMessage !== null) {
        gleamLspStreams.writer.write(transformedMessage);
      }
    });

    const gleamLspStreams = {
      reader: new rpc.StreamMessageReader(gleamLspProcess.stdout),
      writer: new rpc.StreamMessageWriter(gleamLspProcess.stdin),
    };

    gleamLspStreams.reader.listen(async (data) => {
      const transformedMessage = await transformOutgoingMessage(data);
      if (transformedMessage !== null) {
        editorStreams.writer.write(transformedMessage);
      }
    });
  } catch (e) {
    console.error(e);
  }
}
