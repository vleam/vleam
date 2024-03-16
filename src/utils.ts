import * as fs from "node:fs/promises";
import * as path from "path";

const TEMP_DIR = "vleam_generated";
export const baseGeneratedGleamPath = (srcPath: string) =>
  path.join(srcPath, TEMP_DIR);

export async function toGleamPath(
  srcPath: string,
  vuePath: string,
): Promise<string> {
  vuePath = vuePath.replace(".vue", ".gleam");

  const relativeModulePath = path.relative(srcPath, path.dirname(vuePath));
  const moduleFileName = path.basename(vuePath).toLowerCase();

  const pathResult = path.join(
    baseGeneratedGleamPath(srcPath),
    relativeModulePath,
    moduleFileName,
  );

  await fs.mkdir(path.dirname(pathResult), { recursive: true });

  return pathResult;
}
