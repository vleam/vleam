import * as fs from "fs";
import MagicString from "magic-string";
import type { Plugin, PluginOption, UserConfig } from "vite";
import { parse } from "@vue/compiler-sfc";
import * as path from "path";
import { rimrafSync } from "rimraf";
import { toGleamPath, baseGeneratedGleamPath } from "./utils";
import vitePluginGleam from "vite-gleam";

export function vitePluginVueVleam(): PluginOption {
  return [vitePluginVueGleamScript(), vitePluginGleam() as unknown as Plugin];
}

export function vitePluginVueGleamScript(): Plugin {
  const srcPath = path.join(process.cwd(), "./src");

  return {
    name: "vite-plugin-vue-gleam-script",
    enforce: "pre",
    buildStart(_options) {
      rimrafSync(baseGeneratedGleamPath(srcPath));
    },
    async handleHotUpdate({ modules, server }) {
      if (modules.some(({ info }) => info?.meta?.vueGleam?.isGleamScript)) {
        server.hot.send({
          type: "full-reload",
        });
        return [];
      }
    },
    transform(code, id) {
      if (!id.endsWith(".vue")) {
        return;
      }

      const { descriptor } = parse(code);

      const scriptBlock = descriptor.script;

      if (scriptBlock?.lang !== "gleam") {
        return;
      }

      const gleamTargetPath = toGleamPath(srcPath, id);

      fs.writeFileSync(gleamTargetPath, scriptBlock.content, {
        encoding: "utf8",
      });

      const relativeGleamPath = path.relative(
        path.dirname(id),
        gleamTargetPath,
      );

      const magicString = new MagicString(code)
        .replace(
          scriptBlock.content,

          `import { default_export } from "${relativeGleamPath}";\n` +
            "export default default_export();\n",
        )
        .replace('lang="gleam"', 'lang="ts"');

      return {
        code: magicString.toString(),
        map: magicString.generateMap({
          source: id,
          includeContent: true,
        }),
        meta: {
          vueGleam: {
            isGleamScript: true,
          },
        },
      };
    },
  } satisfies Plugin;
}
