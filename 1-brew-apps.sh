#!/bin/bash
# Run as your normal user; sudo is requested only to bootstrap Homebrew.
set -u
set -o pipefail

if [[ "$(uname -s)" != Darwin ]]; then
    echo "This script requires macOS." >&2
    exit 1
fi
macos_version=$(sw_vers -productVersion) || exit 1
if [[ "${macos_version%%.*}" -lt 15 || "$EUID" -eq 0 ]]; then
    echo "Run as your normal user on macOS 15 or newer, without sudo." >&2
    exit 1
fi

failures=()
run() {
    if "$@"; then
        return 0
    else
        failures+=("$*")
        printf '[FAILED] %s\n' "$*" >&2
        return 1
    fi
}

echo "Starting app setup for macOS $macos_version."

# Also find an existing installation when this shell's PATH is incomplete.
BREW_BIN=$(command -v brew || true)
if [[ -z "$BREW_BIN" ]]; then
    if [[ "$(uname -m)" == arm64 ]]; then
        BREW_BIN="/opt/homebrew/bin/brew"
    else
        BREW_BIN="/usr/local/bin/brew"
    fi
    if [[ ! -x "$BREW_BIN" ]]; then
        # Authenticate before NONINTERACTIVE makes the installer use sudo -n.
        run sudo -v || exit 1
        if ! installer=$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh); then
            echo "Could not download the Homebrew installer." >&2
            exit 1
        fi
        run env NONINTERACTIVE=1 /bin/bash -c "$installer" || exit 1
    fi
fi
if [[ ! -x "$BREW_BIN" ]]; then
    echo "Homebrew installation did not produce $BREW_BIN." >&2
    exit 1
fi
brew_env=$("$BREW_BIN" shellenv) || exit 1
eval "$brew_env" || exit 1

case "${SHELL:-/bin/zsh}" in
    */bash) SHELL_PROFILE="$HOME/.bash_profile" ;;
    *) SHELL_PROFILE="$HOME/.zprofile" ;;
esac
add_profile_line() {
    if [[ -f "$SHELL_PROFILE" ]] && grep -Fqx "$1" "$SHELL_PROFILE"; then
        return 0
    fi
    if ! printf '\n%s\n' "$1" >> "$SHELL_PROFILE"; then
        failures+=("Update $SHELL_PROFILE")
        echo "Could not update $SHELL_PROFILE." >&2
        return 1
    fi
}
add_profile_line "eval \"\$(\"$BREW_BIN\" shellenv)\""
# Do not source a zsh profile from Bash.
run brew update

CLI_APPS=(
    wget
    speedtest-go
    dockutil
    tree
    node
    go
    bash-completion@2
    ncdu
    duti
    php
    mariadb
    phpmyadmin
    ffmpeg-full
    composer
    yt-dlp
)

CASK_APPS=(
    the-unarchiver
    google-chrome
    appcleaner
    raycast
    android-studio
    handbrake-app
    vlc
    rapidapi
    cyberduck
    visual-studio-code
    telegram
    whatsapp
    claude-code
    chatgpt
    codex
    jarvis322/tap/sysdata
)
# TinyPNG4Mac is disabled upstream because it fails Gatekeeper checks.
# speedtest-go replaces the deprecated speedtest-cli and provides speedtest.
if brew list --formula speedtest-cli >/dev/null 2>&1; then
    run brew unlink speedtest-cli
fi

echo "Installing CLI tools..."
for app in "${CLI_APPS[@]}"; do
    if brew list --formula "$app" >/dev/null 2>&1; then
        printf '[INSTALLED] %s\n' "$app"
    else
        run brew install --formula "$app"
    fi
done

# ffmpeg-full is keg-only, so make its binaries available to yt-dlp and shells.
if brew list --formula ffmpeg-full >/dev/null 2>&1; then
    if ffmpeg_prefix=$(brew --prefix ffmpeg-full); then
        export PATH="$ffmpeg_prefix/bin:$PATH"
        add_profile_line "export PATH=\"$ffmpeg_prefix/bin:\$PATH\""
    else
        failures+=("Find ffmpeg-full prefix")
    fi
fi

echo "Installing applications..."
for app in "${CASK_APPS[@]}"; do
    if brew list --cask "${app##*/}" >/dev/null 2>&1; then
        printf '[INSTALLED] %s\n' "$app"
    else
        run brew install --cask "$app"
    fi
done

if brew list --formula mariadb >/dev/null 2>&1; then
    run brew services start mariadb
fi
run brew cleanup

if [[ "${#failures[@]}" -gt 0 ]]; then
    printf '\nApp setup finished with %s failure(s):\n' "${#failures[@]}" >&2
    printf '  - %s\n' "${failures[@]}" >&2
    exit 1
fi
echo "App setup completed. Open a new terminal before running the settings script."
