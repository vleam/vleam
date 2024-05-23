import * as fs from "node:fs/promises";
import MagicString from "magic-string";
import type { Plugin } from "vite";
import {
  gleamBuild,
  toVleamGeneratedPath,
  cleanGenerated,
  readCompiledGleamFile,
  gleamProjectName,
  resolveGleamImport,
  getGleamBlockFromCode,
} from "./utils";

export type VleamQuery = {};

export function parseVleamRequest(id: string): {
  filename: string;
  query: VleamQuery;
} {
  const [filename] = id.split(`?`, 2);
  return {
    filename,
    query: {},
  };
}

export async function vitePluginVueVleam(): Promise<Plugin> {
  const projectRoot = process.cwd();
  const projectName = await gleamProjectName(projectRoot);

  const gleamScriptSfcs = new Set();

  return {
    name: "vite-plugin-vue-gleam-script",
    enforce: "pre",
    async buildStart() {
      await cleanGenerated(projectRoot);

      await gleamBuild();
    },
    async resolveId(source, importer) {
      if (!importer) {
        return;
      }

      const { filename } = parseVleamRequest(importer);

      const shouldResolve =
        filename.endsWith(".gleam") ||
        filename === "./gleam.mjs" ||
        gleamScriptSfcs.has(filename);

      if (!shouldResolve) {
        return;
      }

      const resolvedGleamImport = await resolveGleamImport(
        projectRoot,
        filename,
        source,
        projectName,
      );

      if (resolvedGleamImport) {
        return { id: resolvedGleamImport };
      }
    },
    async handleHotUpdate({ modules, server, file }) {
      if (modules.some(({ info }) => info?.meta?.vueGleam?.isGleamScript)) {
        server.hot.send({
          type: "full-reload",
        });
        return [];
      }

      const { filename } = parseVleamRequest(file);

      if (filename.endsWith("gleam.mjs")) {
        return [];
      }

      if (filename.endsWith(".gleam")) {
        await gleamBuild();
      }

      return modules;
    },
    async transform(code, id) {
      const { filename } = parseVleamRequest(id);
      if (filename.endsWith(".vue")) {
        const gleamTargetPath = await toVleamGeneratedPath(
          projectRoot,
          filename,
        );

        const gleamBlock = getGleamBlockFromCode(code);

        if (!gleamBlock) {
          return;
        }

        await fs.writeFile(gleamTargetPath, gleamBlock.content, {
          encoding: "utf8",
        });

        await gleamBuild();

        const compiledContent = await readCompiledGleamFile(
          projectRoot,
          gleamTargetPath,
          projectName,
        );

        const magicString = new MagicString(code)
          .replace(
            gleamBlock.content,
            compiledContent + "\nexport default default_export();",
          )
          .replace('lang="gleam"', 'lang="ts"');

        gleamScriptSfcs.add(filename);

        return {
          code: magicString.toString(),
          map: magicString.generateMap({
            source: filename,
            includeContent: true,
          }),
          meta: {
            vueGleam: {
              isGleamScript: true,
            },
          },
        };
      } else if (filename.endsWith(".gleam")) {
        const compiledContent = await readCompiledGleamFile(
          projectRoot,
          filename,
          projectName,
        );

        const magicString = new MagicString(code)
          .replace(code, compiledContent)
          .replace('lang="gleam"', 'lang="ts"');

        return {
          code: magicString.toString(),
          map: magicString.generateMap({
            source: filename,
            includeContent: true,
          }),
        };
      }
    },
  } satisfies Plugin;
}
