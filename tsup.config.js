import { defineConfig } from "tsup";

export default defineConfig({
  entry: ["src/index.ts", "src/cli.ts"],

  clean: true,
  target: "es2022",
  format: ["esm"],

  bundle: true,
  dts: {
    resolve: true,
    entry: "src/index.ts",
    compilerOptions: {
      module: "es2022",
      moduleResolution: "node",
      types: ["vite/client", "node"],
    },
  },
});
