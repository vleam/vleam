import * as fs from "fs";
import * as path from "path";

const TEMP_DIR = "vleam_generated";
export const baseGeneratedGleamPath = (srcPath: string) =>
  path.join(srcPath, TEMP_DIR);

export function toGleamPath(srcPath: string, vuePath: string): string {
  vuePath = vuePath.replace(".vue", ".gleam");

  const relativeModulePath = path.relative(srcPath, path.dirname(vuePath));
  const moduleFileName = path.basename(vuePath).toLowerCase();

  const pathResult = path.join(
    baseGeneratedGleamPath(srcPath),
    relativeModulePath,
    moduleFileName,
  );

  fs.mkdirSync(path.dirname(pathResult), { recursive: true });

  return pathResult;
}
