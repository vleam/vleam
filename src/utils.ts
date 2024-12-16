import * as fs from "node:fs/promises";
import * as path from "path";
import { parse as parseToml } from "toml";
import { exec } from "node:child_process";
import { rimraf } from "rimraf";
import { parse as vueParse } from "@vue/compiler-sfc";

export const GEN_DIR = "vleam_generated";
const SRC_DIR = "src";
const GLEAM_COMPILED_ROOT = "build/dev/javascript";
export const baseGeneratedGleamPath = (projectRoot: string) =>
  path.join(projectRoot, SRC_DIR, GEN_DIR);

export async function cleanGenerated(projectRoot: string) {
  rimraf(baseGeneratedGleamPath(projectRoot));
}

export async function toVleamGeneratedPath(
  projectRoot: string,
  vuePath: string,
): Promise<string> {
  const srcPath = path.join(projectRoot, SRC_DIR);

  const relativeModulePath = path
    .relative(srcPath, path.dirname(vuePath))
    .toLowerCase();

  const moduleFileName = path
    .basename(vuePath)
    .toLowerCase()
    .replace(".vue", ".gleam");

  const pathResult = path.join(
    baseGeneratedGleamPath(projectRoot),
    relativeModulePath,
    moduleFileName,
  );

  await fs.mkdir(path.dirname(pathResult), { recursive: true });

  return pathResult;
}

export async function toVueOriginalPath(
  projectRoot: string,
  vleamGeneratedPath: string,
): Promise<string | undefined> {
  const relativeModulePath = path
    .relative(
      baseGeneratedGleamPath(projectRoot),
      path.dirname(vleamGeneratedPath),
    )
    .toLowerCase();

  const moduleFileName = path
    .basename(vleamGeneratedPath)
    .replace(".gleam", "");

  const srcPath = path.join(projectRoot, SRC_DIR);

  const vueFolder = path.join(srcPath, relativeModulePath);

  try {
    const vueFile = (
      await fs.readdir(vueFolder, {
        withFileTypes: true,
        recursive: false,
      })
    ).find(
      (filename) =>
        filename.name.replace(".vue", "").toLowerCase() === moduleFileName,
    );

    return vueFile && path.join(vueFolder, vueFile?.name);
  } catch (_e) {
    // No such folder, skip
  }
}

export function getGleamBlockFromCode(sfcCode: string) {
  const { descriptor } = vueParse(sfcCode);

  const scriptBlock = descriptor.script;

  if (scriptBlock?.lang !== "gleam") {
    return null;
  }

  return scriptBlock;
}

const BUILD_COMMAND = "gleam build --target=javascript";
export async function gleamBuild(isLog = false) {
  if (isLog) {
    console.log(`$ ${BUILD_COMMAND}`);
  }

  const result = await new Promise<{ stdout: string; stderr: string }>(
    (res, rej) =>
      exec(
        BUILD_COMMAND,
        {
          encoding: "utf8",
        },
        (err, stdout, stderr) => {
          if (err) {
            return rej(err);
          } else {
            res({ stdout, stderr });
          }
        },
      ),
  );

  if (isLog) {
    console.log(result.stdout);
    console.error(result.stderr);
  }

  return result;
}

export async function gleamProjectName(projectRoot: string) {
  const gleamTomlPath = path.join(projectRoot, "gleam.toml");
  const error = Error("gleam.toml not found");
  if (!(await fs.lstat(gleamTomlPath)).isFile()) {
    throw error;
  }

  const gleamTomlContents = await fs.readFile(gleamTomlPath, {
    encoding: "utf8",
  });

  const name = parseToml(gleamTomlContents)?.name;

  if (!name) {
    throw error;
  }

  return name;
}

async function resolveGleamCompiledPath(
  projectRoot: string,
  filePath: string,
  projectName?: string,
) {
  const actualName = projectName ?? (await gleamProjectName(projectRoot));
  const srcPath = path.join(projectRoot, SRC_DIR);

  const gleamFilePath = filePath.toLowerCase().endsWith(".vue")
    ? await toVleamGeneratedPath(projectRoot, filePath)
    : filePath;

  const sourceRelPath = path.isAbsolute(gleamFilePath)
    ? path.relative(srcPath, gleamFilePath)
    : gleamFilePath;

  return path.join(
    projectRoot,
    GLEAM_COMPILED_ROOT,
    actualName,
    sourceRelPath.replace(".gleam", ".mjs"),
  );
}

export async function rewriteGleamImports(
  projectRoot: string,
  filePath: string,
  importPath: string,
  projectName?: string,
) {
  const origin = importPath;
  if (importPath.startsWith("hex:")) {
    return path.join(projectRoot, GLEAM_COMPILED_ROOT, importPath.slice(4));
  } else if (importPath.endsWith(".gleam")) {
    // src is hardcoded because that's how Gleam works
    if (importPath.startsWith("/src")) {
      importPath = importPath.slice(5);
    } else if (importPath.startsWith(".")) {
      importPath = path.resolve(path.dirname(filePath), importPath);
    } else {
      // must start with a `.` or `/src`, otherwise can be `hex`/`npm` import
      return;
    }

    return await resolveGleamCompiledPath(projectRoot, importPath, projectName);
  }
}

export async function rewriteRelativeImports(
  projectRoot: string,
  filePath: string,
  importPath: string,
  projectName?: string,
) {
  // must start with a `.`, otherwise can be `hex`/`npm` import
  if (!importPath.startsWith(".")) {
    return;
  }

  const compiledPath = await resolveGleamCompiledPath(
    projectRoot,
    filePath,
    projectName,
  );

  return path.join(path.dirname(compiledPath), importPath);
}

export async function readCompiledGleamFile(
  projectRoot: string,
  filePath: string,
  projectName?: string,
) {
  const compiledPath = await resolveGleamCompiledPath(
    projectRoot,
    filePath,
    projectName,
  );

  return fs.readFile(compiledPath, {
    encoding: "utf8",
  });
}
