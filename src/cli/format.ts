import * as fs from "fs";
import * as child_process from "child_process";

import { getGleamScriptBlock } from "./_utils";

export default function action(options: any) {
  if (!options.stdin) {
    console.error("Formatting is only supported with the --stdin flag\n");
    return;
  }

  const vueFileContent = fs.readFileSync(process.stdin.fd, "utf-8");
  const { gleamScriptBlock, errors } = getGleamScriptBlock(vueFileContent);

  if (gleamScriptBlock) {
    const gleamFormatProcess = child_process.spawn(
      "gleam",
      ["format", "--stdin"],
      {
        shell: false,
      },
    );

    gleamFormatProcess.stdout.on("data", (data) => {
      const formattedVue = vueFileContent.replace(
        gleamScriptBlock.content,
        "\n" + data.toString(),
      );
      process.stdout.write(formattedVue);
    });
    gleamFormatProcess.stderr.pipe(process.stderr);
    gleamFormatProcess.stdin.write(gleamScriptBlock.content);
    gleamFormatProcess.stdin.destroy();
  } else {
    console.error("Unable to parse Vue SFC\n");
  }

  if (errors.length) {
    console.error(`Errors parsing Vue SFC: ${errors.join("\n")}\n`);
  }
}
