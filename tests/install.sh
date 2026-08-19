#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

assert_file() {
    [ -e "$1" ] || fail "expected file to exist: $1"
}

assert_contains() {
    local file="$1"
    local text="$2"
    grep -Fq -- "$text" "$file" || fail "expected $file to contain: $text"
}

assert_not_contains() {
    local file="$1"
    local text="$2"
    if grep -Fq -- "$text" "$file"; then
        fail "expected $file not to contain: $text"
    fi
}

write_executable() {
    local path="$1"
    shift
    cat > "$path" <<EOF
#!/bin/bash
$*
EOF
    chmod +x "$path"
}

make_stub_home() {
    mktemp -d "${TMPDIR:-/tmp}/posh-themer-home.XXXXXX"
}

make_stub_bin() {
    mktemp -d "${TMPDIR:-/tmp}/posh-themer-bin.XXXXXX"
}

stub_success_commands() {
    local stub_bin="$1"

    write_executable "$stub_bin/jq" 'exit 0'
    write_executable "$stub_bin/zsh" 'exit 0'
    write_executable "$stub_bin/unzip" '
while [ "$#" -gt 0 ]; do
    if [ "$1" = "-d" ]; then
        shift
        mkdir -p "$1"
        touch "$1/jandedobbeleer.omp.json"
        exit 0
    fi
    shift
done
exit 1
'
    write_executable "$stub_bin/curl" '
if [ "$#" -ge 2 ] && [ "${*: -2:1}" = "-o" ]; then
    out="${*: -1}"
    printf "stub zip" > "$out"
    exit 0
fi

case "$*" in
    *deno.land*)
        cat <<'"'"'SCRIPT'"'"'
mkdir -p "$HOME/.deno/bin"
cat > "$HOME/.deno/bin/deno" <<'"'"'DENO'"'"'
#!/usr/bin/env bash
exit 0
DENO
chmod +x "$HOME/.deno/bin/deno"
SCRIPT
        ;;
    *ohmyposh.dev*)
        cat <<'"'"'SCRIPT'"'"'
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/oh-my-posh" <<'"'"'OMP'"'"'
#!/usr/bin/env bash
exit 0
OMP
chmod +x "$HOME/.local/bin/oh-my-posh"
SCRIPT
        ;;
    *)
        exit 1
        ;;
esac
'
    write_executable "$stub_bin/git" '
if [ "$1" = "clone" ]; then
    mkdir -p "$HOME/posh_themer"
    cp "$POSH_THEMER_REPO_ROOT/posh_theme.sh" "$HOME/posh_themer/posh_theme.sh"
    exit 0
fi
exit 1
'
}

stub_basic_commands() {
    local stub_bin="$1"

    write_executable "$stub_bin/bash" '/bin/bash "$@"'
    write_executable "$stub_bin/sh" '/bin/sh "$@"'
    write_executable "$stub_bin/awk" '/usr/bin/awk "$@"'
    write_executable "$stub_bin/cat" '/bin/cat "$@"'
    write_executable "$stub_bin/chmod" '/bin/chmod "$@"'
    write_executable "$stub_bin/cp" '/bin/cp "$@"'
    write_executable "$stub_bin/grep" '/bin/grep "$@"'
    write_executable "$stub_bin/mkdir" '/bin/mkdir "$@"'
    write_executable "$stub_bin/mktemp" '/bin/mktemp "$@"'
    write_executable "$stub_bin/mv" '/bin/mv "$@"'
    write_executable "$stub_bin/rm" '/bin/rm "$@"'
    write_executable "$stub_bin/touch" '/bin/touch "$@"'
}

test_successful_install_prepares_dependencies() {
    local home stub_bin log
    home="$(make_stub_home)"
    stub_bin="$(make_stub_bin)"
    log="$home/install.log"
    stub_basic_commands "$stub_bin"
    stub_success_commands "$stub_bin"

    HOME="$home" \
    POSH_THEMER_REPO_ROOT="$ROOT_DIR" \
    POSH_THEMER_SHELL=zsh \
    PATH="$stub_bin" \
        /bin/bash "$ROOT_DIR/install.sh" > "$log" 2>&1

    assert_file "$home/.deno/bin/deno"
    assert_file "$home/.local/bin/oh-my-posh"
    assert_file "$home/.cache/oh-my-posh/themes/jandedobbeleer.omp.json"
    assert_file "$home/.local/bin/posh_theme"
    assert_contains "$home/.zshrc" 'oh-my-posh init zsh'
    assert_contains "$home/.zshrc" '--strict'
    [ ! -e "$home/.config/posh_themer/omarchy-starship-guard.bash" ] || \
        fail "non-Omarchy install unexpectedly created Omarchy compatibility files"
    assert_contains "$log" "checking required dependencies"
}

test_successful_bash_install_configures_bashrc() {
    local home stub_bin log
    home="$(make_stub_home)"
    stub_bin="$(make_stub_bin)"
    log="$home/install.log"
    stub_basic_commands "$stub_bin"
    stub_success_commands "$stub_bin"

    HOME="$home" \
    POSH_THEMER_REPO_ROOT="$ROOT_DIR" \
    POSH_THEMER_SHELL=bash \
    PATH="$stub_bin" \
        /bin/bash "$ROOT_DIR/install.sh" > "$log" 2>&1

    assert_file "$home/.local/bin/posh_theme"
    assert_contains "$home/.bashrc" 'oh-my-posh init bash'
    assert_contains "$home/.bashrc" '--strict'
    assert_contains "$log" "configuring bash prompt"
    [ ! -f "$home/.zshrc" ] || fail "bash install should not configure .zshrc"
}

test_omarchy_bash_disables_only_starship_prompt_init() {
    local home stub_bin omarchy_root log shell_log
    home="$(make_stub_home)"
    stub_bin="$(make_stub_bin)"
    omarchy_root="$home/omarchy"
    log="$home/install.log"
    shell_log="$home/shell.log"
    stub_basic_commands "$stub_bin"
    stub_success_commands "$stub_bin"

    mkdir -p "$omarchy_root/default/bash"
    cat > "$omarchy_root/default/bash/init" <<'EOF'
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi
EOF
    cat > "$omarchy_root/default/bash/rc" <<'EOF'
source "$OMARCHY_PATH/default/bash/init"
EOF
    cat > "$home/.bashrc" <<'EOF'
source "$OMARCHY_PATH/default/bash/rc"
EOF
    write_executable "$stub_bin/starship" '
if [ "${1:-}" = init ] && [ "${2:-}" = bash ]; then
    printf "STARSHIP_INITIALIZED=1\n"
    exit 0
fi
printf "starship command still available\n"
'

    HOME="$home" \
    POSH_THEMER_REPO_ROOT="$ROOT_DIR" \
    POSH_THEMER_SHELL=bash \
    POSH_THEMER_OMARCHY_PATH="$omarchy_root" \
    PATH="$stub_bin" \
        /bin/bash "$ROOT_DIR/install.sh" > "$log" 2>&1

    assert_file "$home/.config/posh_themer/omarchy-starship-guard.bash"
    assert_contains "$home/.bashrc" 'source "$HOME/.config/posh_themer/omarchy-starship-guard.bash"'
    assert_contains "$home/.bashrc" 'posh_themer_restore_starship'
    assert_contains "$home/.bashrc" 'oh-my-posh init bash --strict'
    assert_contains "$log" "configuring Omarchy to use Oh My Posh instead of Starship"

    write_executable "$home/.local/bin/oh-my-posh" '
if [ "${1:-}" = init ] && [ "${2:-}" = bash ]; then
    printf "POSH_INITIALIZED=1\n"
fi
'

    HOME="$home" OMARCHY_PATH="$omarchy_root" PATH="$stub_bin" \
        /bin/bash --noprofile --norc -c \
        'source "$HOME/.bashrc"; printf "starship=%s posh=%s\n" "${STARSHIP_INITIALIZED:-0}" "${POSH_INITIALIZED:-0}"; starship version' \
        > "$shell_log" 2>&1

    assert_contains "$shell_log" "starship=0 posh=1"
    assert_contains "$shell_log" "starship command still available"
    assert_not_contains "$shell_log" "STARSHIP_INITIALIZED=1"

    # Reinstalling must not duplicate the managed guard.
    HOME="$home" \
    POSH_THEMER_REPO_ROOT="$ROOT_DIR" \
    POSH_THEMER_SHELL=bash \
    POSH_THEMER_OMARCHY_PATH="$omarchy_root" \
    PATH="$stub_bin" \
        /bin/bash "$ROOT_DIR/install.sh" >> "$log" 2>&1

    [ "$(grep -Fc 'source "$HOME/.config/posh_themer/omarchy-starship-guard.bash"' "$home/.bashrc")" -eq 1 ] || \
        fail "Omarchy compatibility guard was duplicated"
}

test_installs_unzip_with_pacman_before_deno_when_extractor_missing() {
    local home stub_bin log
    home="$(make_stub_home)"
    stub_bin="$(make_stub_bin)"
    log="$home/install.log"
    stub_success_commands "$stub_bin"
    stub_basic_commands "$stub_bin"
    rm -f "$stub_bin/unzip"

    write_executable "$stub_bin/pacman" 'exit 0'
    write_executable "$stub_bin/sudo" '
if [ "$1" = "pacman" ] && [ "$2" = "-S" ]; then
    package="${@: -1}"
    if [ "$package" = "unzip" ]; then
        cat > "$STUB_BIN/unzip" <<'"'"'UNZIP'"'"'
#!/usr/bin/env bash
while [ "$#" -gt 0 ]; do
    if [ "$1" = "-d" ]; then
        shift
        mkdir -p "$1"
        touch "$1/jandedobbeleer.omp.json"
        exit 0
    fi
    shift
done
exit 1
UNZIP
        chmod +x "$STUB_BIN/unzip"
    fi
fi
exit 0
'

    HOME="$home" \
    POSH_THEMER_REPO_ROOT="$ROOT_DIR" \
    POSH_THEMER_SHELL=zsh \
    STUB_BIN="$stub_bin" \
    PATH="$stub_bin" \
        /bin/bash "$ROOT_DIR/install.sh" > "$log" 2>&1

    assert_contains "$log" "unzip is required to extract oh-my-posh themes"
    assert_file "$stub_bin/unzip"
    assert_file "$home/.deno/bin/deno"
}

test_aborts_before_clone_without_package_manager() {
    local home stub_bin log
    home="$(make_stub_home)"
    stub_bin="$(make_stub_bin)"
    log="$home/install.log"

    write_executable "$stub_bin/curl" 'exit 0'
    write_executable "$stub_bin/git" '
if [ "$1" = "clone" ]; then
    echo "git clone should not run" >&2
    exit 42
fi
exit 0
'
    write_executable "$stub_bin/jq" 'exit 0'
    write_executable "$stub_bin/cat" '/bin/cat "$@"'
    write_executable "$stub_bin/mkdir" '/bin/mkdir "$@"'

    if HOME="$home" POSH_THEMER_SHELL=zsh PATH="$stub_bin" /bin/bash "$ROOT_DIR/install.sh" > "$log" 2>&1; then
        fail "installer unexpectedly succeeded"
    fi

    assert_contains "$log" "no supported package manager was found"
    [ ! -d "$home/posh_themer" ] || fail "repo was cloned before dependency preflight completed"
}

test_successful_install_prepares_dependencies
test_successful_bash_install_configures_bashrc
test_omarchy_bash_disables_only_starship_prompt_init
test_installs_unzip_with_pacman_before_deno_when_extractor_missing
test_aborts_before_clone_without_package_manager

echo "install.sh tests passed"
