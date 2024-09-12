import * as compiler from "@vue/compiler-dom";
import type {
  CompilerError,
  SFCBlock,
  SFCStyleBlock,
  SFCScriptBlock,
} from "@vue/compiler-sfc";
import type { ElementNode } from "@vue/compiler-core";

// This is from @vuejs/core
export function createSFCBlock(node: ElementNode, source: string) {
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
      const scriptBlock = createSFCBlock(node, source) as SFCScriptBlock;
      const isSetup = !!scriptBlock.attrs.setup;
      if (!isSetup && scriptBlock.lang === "gleam") {
        resultBlock = scriptBlock;
      }
    }
  });

  return { gleamScriptBlock: resultBlock as SFCScriptBlock | null, errors };
}
