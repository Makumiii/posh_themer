/**
 * Posh Themer - Interactive Oh My Posh Theme Selector
 *
 * Browse, preview, and apply oh-my-posh themes with a beautiful TUI
 */

import { pickTheme } from "./src/ui/theme-picker.ts";

// Configuration paths
const THEMES_PATH = "/home/maks/.cache/oh-my-posh/themes";
const ZSHRC_PATH = "/home/maks/.zshrc";

/**
 * Get all theme files from the themes directory
 */
function getThemes(path: string): string[] {
  try {
    const files = Deno.readDirSync(path);
    const filesArray = Array.from(files);
    return filesArray
      .filter((file) => file.isFile && file.name.endsWith(".omp.json"))
      .map((file) => file.name)
      .sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()));
  } catch (error) {
    console.error(`Error reading themes directory: ${error}`);
    return [];
  }
}

/**
 * Apply the selected theme to .zshrc
 */
async function applyTheme(themeName: string): Promise<boolean> {
  try {
    const decoder = new TextDecoder("utf-8");
    const zshConfig = await Deno.readFile(ZSHRC_PATH);
    const data = decoder.decode(zshConfig);

    // Find the existing oh-my-posh configuration line
    const themeLine = data
      .split("\n")
      .find((line) => line.includes("oh-my-posh") && line.includes("--config"));

    const newLine =
      `eval "$(oh-my-posh init zsh --config ${THEMES_PATH}/${themeName})"`;

    if (!themeLine) {
      // No existing config found, append the new line
      console.log("\n⚠️  No existing oh-my-posh configuration found in .zshrc");
      console.log("   Adding new configuration...");
      await Deno.writeTextFile(ZSHRC_PATH, data + "\n" + newLine + "\n");
    } else {
      // Replace existing config
      const withNewPath = data.replace(themeLine, newLine);
      await Deno.writeTextFile(ZSHRC_PATH, withNewPath);
    }

    return true;
  } catch (error) {
    console.error(`Error applying theme: ${error}`);
    return false;
  }
}

/**
 * Main application entry point
 */
async function main(): Promise<void> {
  console.log("\n🎨 Posh Themer - Oh My Posh Theme Selector\n");

  // Get available themes
  const themes = getThemes(THEMES_PATH);

  if (themes.length === 0) {
    console.error("❌ No themes found in", THEMES_PATH);
    console.log(
      "\nMake sure oh-my-posh is installed and themes are downloaded.",
    );
    console.log("You can download themes with: oh-my-posh font install");
    Deno.exit(1);
  }

  console.log(`📂 Found ${themes.length} themes in ${THEMES_PATH}`);
  console.log("   Loading interactive picker...\n");

  // Small delay so user can see the message
  await new Promise((resolve) => setTimeout(resolve, 500));

  // Launch interactive picker
  const result = await pickTheme({
    themes,
    themesPath: THEMES_PATH,
    pageSize: 10,
    message: "🎨 Select a theme (use ↑↓ to navigate, type to filter):",
  });

  if (result.cancelled || !result.selected) {
    console.log("\n❌ Theme selection cancelled.\n");
    Deno.exit(0);
  }

  console.log(`\n✨ Selected theme: ${result.selected}`);

  // Apply the theme
  const applied = await applyTheme(result.selected);

  if (applied) {
    console.log("\n✅ Theme applied successfully!");
    console.log("   Restarting shell to apply changes...\n");

    // Spawn a new zsh shell to immediately apply the theme
    // This replaces the current process with a fresh shell
    const shell = new Deno.Command("zsh", {
      args: ["-l"], // Login shell to load full config
      stdin: "inherit",
      stdout: "inherit",
      stderr: "inherit",
    });

    const process = shell.spawn();
    const status = await process.status;
    Deno.exit(status.code);
  } else {
    console.log("\n❌ Failed to apply theme.\n");
    Deno.exit(1);
  }
}

// Run the app
await main();
