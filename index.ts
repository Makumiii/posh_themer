/**
 * Posh Themer - Interactive Oh My Posh Theme Selector
 *
 * Browse, preview, and apply oh-my-posh themes with a beautiful TUI
 */

import { pickTheme } from "./src/ui/theme-picker.ts";

// Configuration paths
const HOME = Deno.env.get("HOME");

if (!HOME) {
  console.error(
    "HOME is not set; cannot locate Oh My Posh themes or shell config.",
  );
  Deno.exit(1);
}

const THEMES_PATH = `${HOME}/.cache/oh-my-posh/themes`;

type SupportedShell = "bash" | "zsh";

interface ShellConfig {
  name: SupportedShell;
  configPath: string;
  restartArgs: string[];
}

function shellNameFromPath(path: string | undefined): string {
  if (!path) return "";
  const parts = path.split("/");
  return parts[parts.length - 1] ?? "";
}

function detectShell(): ShellConfig {
  const requestedShell = Deno.env.get("POSH_THEMER_SHELL");
  const shellName = shellNameFromPath(requestedShell ?? Deno.env.get("SHELL"));

  if (shellName === "bash") {
    return {
      name: "bash",
      configPath: `${HOME}/.bashrc`,
      restartArgs: ["-i"],
    };
  }

  if (shellName === "zsh") {
    return {
      name: "zsh",
      configPath: `${HOME}/.zshrc`,
      restartArgs: ["-l"],
    };
  }

  return {
    name: "zsh",
    configPath: `${HOME}/.zshrc`,
    restartArgs: ["-l"],
  };
}

const SHELL_CONFIG = detectShell();

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
 * Apply the selected theme to the active shell config.
 */
async function applyTheme(themeName: string): Promise<boolean> {
  try {
    const decoder = new TextDecoder("utf-8");
    let data = "";
    try {
      const shellConfig = await Deno.readFile(SHELL_CONFIG.configPath);
      data = decoder.decode(shellConfig);
    } catch (error) {
      if (!(error instanceof Deno.errors.NotFound)) {
        throw error;
      }
    }

    // Find the existing oh-my-posh configuration line
    const themeLine = data
      .split("\n")
      .find((line) => line.includes("oh-my-posh") && line.includes("--config"));

    const newLine =
      `eval "$(oh-my-posh init ${SHELL_CONFIG.name} --strict --config "$HOME/.cache/oh-my-posh/themes/${themeName}")"`;

    if (!themeLine) {
      // No existing config found, append the new line
      console.log(
        `\n⚠️  No existing oh-my-posh configuration found in ${SHELL_CONFIG.configPath}`,
      );
      console.log("   Adding new configuration...");
      await Deno.writeTextFile(
        SHELL_CONFIG.configPath,
        data + "\n" + newLine + "\n",
      );
    } else {
      // Replace existing config
      const withNewPath = data.replace(themeLine, newLine);
      await Deno.writeTextFile(SHELL_CONFIG.configPath, withNewPath);
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
    console.log(`   Restarting ${SHELL_CONFIG.name} to apply changes...\n`);

    // Spawn a new shell to immediately apply the theme
    // This replaces the current process with a fresh shell
    const shell = new Deno.Command(SHELL_CONFIG.name, {
      args: SHELL_CONFIG.restartArgs,
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
