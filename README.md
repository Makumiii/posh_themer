# 🌈 posh_themer

A simple CLI tool to preview and switch between your installed
[Oh My Posh](https://ohmyposh.dev) themes — right from your terminal.

---

## ✨ Features

- Preview your installed Oh My Posh themes instantly
- Quickly apply any theme with a numbered selector
- Works with any terminal using `zsh` or `bash`
- Installer prepares `jq`, Deno, Oh My Posh, Oh My Posh themes, and a default
  prompt configuration for your active `bash` or `zsh` shell

---

## ⚙️ Installation

To install `posh_themer`, run the following command in your terminal:

```bash
curl -s https://raw.githubusercontent.com/Makumiii/posh_themer/main/install.sh | bash
```

The installer keeps app-managed tools user-local where possible:

- Deno is installed under `~/.deno/bin`
- Oh My Posh is installed under `~/.local/bin`
- Oh My Posh themes are installed under `~/.cache/oh-my-posh/themes`
- `~/.bashrc` or `~/.zshrc` is updated with `~/.local/bin`, `~/.deno/bin`, and
  the default `jandedobbeleer` prompt based on your active shell

If `jq` or support packages such as `unzip`, `curl`, or `git` are missing on an
`apt-get` based system, the installer uses `sudo apt-get` to install them. On
non-apt systems, install the missing package with your system package manager
and rerun the installer.

## Uninstalling

To uninstall the tool run the following command on your terminal

```bash
posh_theme uninstall
```
