import * as fs from "node:fs/promises";
import * as path from "node:path";
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

// Splits `SFCNames.vue?with=querystring` into
// ```
// {
//   filename: 'SFCNames.vue',
//   query: {
//     with: 'querystring',
//   },
// }
// ```
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

const transform = async (
  code: string,
  id: string,
  { projectRoot, projectName, gleamScriptSfcs },
) => {
  const { filename } = parseVleamRequest(id);

  if (filename.endsWith(".vue")) {
    const gleamTargetPath = await toVleamGeneratedPath(projectRoot, filename);
    const gleamBlock = getGleamBlockFromCode(code);

    if (!gleamBlock) {
      return;
    }

    // Generate the Gleam file
    await fs.writeFile(gleamTargetPath, gleamBlock.content.replace(/^\n/, ""), {
      encoding: "utf8",
    });

    // Compile Gleam code
    await gleamBuild();

    // Get compiled file
    const compiledContent = await readCompiledGleamFile(
      projectRoot,
      gleamTargetPath,
      projectName,
    );

    // Inject compiled code into SFC
    const magicString = new MagicString(code)
      .replace(
        gleamBlock.content,
        compiledContent + "\nexport default default_export();",
      )
      .replace('lang="gleam"', 'lang="ts"');

    // Track SFCs with Gleam scripts
    gleamScriptSfcs.add(filename);

    return {
      code: magicString.toString(),
      map: magicString.generateMap({
        source: filename,
        includeContent: true,
      }),
    };
  } else if (filename.endsWith(".gleam")) {
    // No need to `gleam build` here, we'll build on startup and watch

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
};

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
    async transform(code, id) {
      return transform(code, id, { projectName, projectRoot, gleamScriptSfcs });
    },
    async watchChange(id, _change) {
      const { filename } = parseVleamRequest(id);
      if (filename.endsWith(".gleam")) {
        await gleamBuild();
      }
    },
    async handleHotUpdate(ctx) {
      const { filename } = parseVleamRequest(ctx.file);

      // Send compiled & transformed versions of Gleam scripts and Gleam files
      if (gleamScriptSfcs.has(filename) || filename.endsWith(".gleam")) {
        const { read } = ctx;
        ctx.read = async () => {
          const content = await read();
          const transformed = await transform(content, ctx.file, {
            projectName,
            projectRoot,
            gleamScriptSfcs,
          });

          return transformed?.code || content;
        };
      }
    },
  } satisfies Plugin;
}
