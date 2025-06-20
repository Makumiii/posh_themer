import { select, Separator } from "npm:@inquirer/prompts";
const path = "/home/maks/.cache/oh-my-posh/themes";
const zshPath = "/home/maks/.zshrc";

function getThemes(path: string) {
  const files = Deno.readDirSync(path);
  const filesArray = Array.from(files);
  return filesArray.map((file) => file.name);
}

async function promptThemes() {
  const themes = getThemes(path);


  const answer = await select({
    message: "select the theme you want",
    choices: themes,
    loop:false,
    pageSize:10
  });
  return answer;
}

async function applyTheme() {
  const decoder = new TextDecoder("utf-8");
  const zshConfig = await Deno.readFile(zshPath);
  const data = decoder.decode(zshConfig);
  const themeLine = data
    .split("\n")
    .find((line) => line.includes("oh-my-posh") && line.includes("--config"));
  const chosenTheme = await promptThemes();

  const newLine =
    `eval "$(oh-my-posh init zsh --config ${path}/${chosenTheme} )"`;
  if (!themeLine) {
    console.error("no theme line found. Install oh my posh ");
    return;
  }

  const withNewPath = data.replace(themeLine, newLine);
  await Deno.writeTextFile(zshPath, withNewPath);
  console.log("theme applied successfully");
  Deno.exit();
}

async function App() {

  await applyTheme()
  



}

await App();
