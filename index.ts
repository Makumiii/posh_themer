const path = "/home/maks/.cache/oh-my-posh/themes";
const zshPath = '/home/maks/.zshrc'

function getThemes(path: string) {
  const files = Deno.readDirSync(path);
  const filesArray = Array.from(files);

  let themeNumber = 1;
  for (const file of filesArray) {
    console.log(`${themeNumber}. ${file.name}`);
    themeNumber++;
  }

  return filesArray.map((file) => {
    return file.name;
  });
}

async function applyTheme(themeNumber: number) {
  const decoder = new TextDecoder("utf-8");
  const zshConfig = await Deno.readFile(zshPath);
  const data = decoder.decode(zshConfig);
  const themeLine = data
    .split("\n")
    .find((line) => line.includes("oh-my-posh") && line.includes("--config"));
  const chosenTheme = getThemes(path)[themeNumber - 1] ;


  const newLine = `eval "$(oh-my-posh init zsh --config ${path}/${chosenTheme} )"`;
  if(!themeLine){
    console.error('no theme line found. Install oh my posh ')
    return 
  }
  

  const withNewPath = data.replace(themeLine,newLine)
  await Deno.writeTextFile(zshPath, withNewPath)
  console.log('theme applied successfully')
  Deno.exit()
  
}

async function App() {
  getThemes(path);
  const theme = prompt("which theme do you want to pick?");
  console.log(theme);
  if (!theme) {
    console.error("invalid theme");
    return;
  }
  const formattedTheme = theme.trim();
  await applyTheme(Number(formattedTheme));
}

await App();
