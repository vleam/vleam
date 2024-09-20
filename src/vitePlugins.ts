import * as fs from "node:fs/promises";
import MagicString from "magic-string";
import type { Plugin, ResolvedConfig, ViteDevServer } from "vite";
import {
  gleamBuild,
  toVleamGeneratedPath,
  cleanGenerated,
  readCompiledGleamFile,
  gleamProjectName,
  resolveGleamImport,
  getGleamBlockFromCode,
  GEN_DIR,
  toVueOriginalPath,
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

const normalizeBuildErrorPaths = async (
  projectRoot: string,
  buildError: string,
) => {
  const possiblePaths =
    buildError.match(new RegExp(`/.*/${GEN_DIR}/.*\\.gleam`, "g")) ?? [];
  let replacedError = buildError;
  for (const path of possiblePaths) {
    const originalPath = await toVueOriginalPath(projectRoot, path);
    if (originalPath) {
      replacedError = replacedError.replace(path, originalPath);
    }
  }

  return replacedError;
};

const handleBuildError = async ({
  projectRoot,
  buildError,
  stack,
  config,
  server,
}: {
  projectRoot: string;
  buildError: any;
  stack: string;
  config: ResolvedConfig;
  server?: ViteDevServer;
}) => {
  config.logger.error(buildError, {
    error: buildError,
    clear: true,
    timestamp: true,
  });

  server?.ws.send({
    type: "error",
    err: {
      message: await normalizeBuildErrorPaths(
        projectRoot,

        buildError.toString(),
      ),
      stack,
    },
  });

  if (buildError && config.command !== "serve") {
    throw buildError;
  }
};

const transform = async (
  code: string,
  id: string,
  {
    projectRoot,
    projectName,
    gleamScriptSfcs,
  }: { projectRoot: string; projectName: string; gleamScriptSfcs: Set<String> },
) => {
  const { filename } = parseVleamRequest(id);

  if (filename.endsWith(".vue")) {
    let buildError: any;
    const gleamTargetPath = await toVleamGeneratedPath(projectRoot, filename);
    const gleamBlock = getGleamBlockFromCode(code);

    if (!gleamBlock) {
      return {};
    }

    // Generate the Gleam file
    await fs.writeFile(gleamTargetPath, gleamBlock.content.replace(/^\n/, ""), {
      encoding: "utf8",
    });

    // Compile Gleam code
    try {
      await gleamBuild();
    } catch (e) {
      buildError = e;
    }

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
      buildError,
      transformation: {
        code: magicString.toString(),
        map: magicString.generateMap({
          source: filename,
          includeContent: true,
        }),
      },
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
      transformation: {
        code: magicString.toString(),
        map: magicString.generateMap({
          source: filename,
          includeContent: true,
        }),
      },
    };
  }

  return {};
};

export async function vitePluginVueVleam(): Promise<Plugin> {
  let config: ResolvedConfig;
  let server: ViteDevServer | undefined;

  const projectRoot = process.cwd();
  const projectName = await gleamProjectName(projectRoot);

  const gleamScriptSfcs = new Set<string>();

  return {
    name: "vite-plugin-vue-gleam-script",
    enforce: "pre",
    configResolved(resolvedConfig) {
      config = resolvedConfig;
    },
    configureServer(wsServer) {
      server = wsServer;
    },
    async buildStart() {
      await cleanGenerated(projectRoot);

      try {
        await gleamBuild();
      } catch (error) {
        handleBuildError({
          config,
          projectRoot,
          server,
          buildError: error,
          stack: "",
        });
      }
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
      const { transformation, buildError } = await transform(code, id, {
        projectName,
        projectRoot,
        gleamScriptSfcs,
      });

      if (buildError) {
        handleBuildError({
          config,
          projectRoot,
          server,
          buildError,
          stack: id,
        });
      }

      return transformation;
    },
    async watchChange(id, _change) {
      const { filename } = parseVleamRequest(id);
      if (filename.endsWith(".gleam")) {
        try {
          await gleamBuild();
        } catch (error) {
          handleBuildError({
            config,
            projectRoot,
            server,
            buildError: error,
            stack: id,
          });
        }
      }
    },
    async handleHotUpdate(ctx) {
      const { read, server } = ctx;
      const { filename } = parseVleamRequest(ctx.file);

      server.ws.send({
        type: "prune",
        paths: [filename, ctx.file],
      });

      // Send compiled & transformed versions of Gleam scripts and Gleam files
      if (gleamScriptSfcs.has(filename) || filename.endsWith(".gleam")) {
        ctx.read = async () => {
          const content = await read();
          const { transformation, buildError } = await transform(
            content,
            ctx.file,
            {
              projectName,
              projectRoot,
              gleamScriptSfcs,
            },
          );

          if (buildError) {
            handleBuildError({
              config,
              projectRoot,
              server,
              buildError,
              stack: filename,
            });
          }

          return transformation?.code || content;
        };
      }
    },
  } satisfies Plugin;
}
