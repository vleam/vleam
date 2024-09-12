import packageJson from "../../package.json";
import { cac } from "cac";

import lspAction from "./lsp";
import formatAction from "./format";

const cli = cac("vleam");

cli.command("lsp").action(lspAction);

cli
  .command(
    "format",
    "format gleam portion of Vue SFC. Currently only supports stdin",
  )
  .option("--stdin", "Accept input on stdin")
  .action(formatAction);

cli.help();

cli.version(packageJson.version);

cli.parse();
