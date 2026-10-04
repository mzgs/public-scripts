#!/bin/bash
# Continue after individual failures, then report them and return a failing status.
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

# The app script may have installed Homebrew in a different shell.
if ! command -v brew >/dev/null 2>&1; then
    if [[ "$(uname -m)" == arm64 ]]; then
        BREW_BIN="/opt/homebrew/bin/brew"
    else
        BREW_BIN="/usr/local/bin/brew"
    fi
    if [[ -x "$BREW_BIN" ]]; then
        brew_env=$("$BREW_BIN" shellenv) || exit 1
        eval "$brew_env" || exit 1
    fi
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

echo "Applying preferences for macOS $macos_version. Close System Settings and apps first."

if command -v duti >/dev/null 2>&1 && [[ -d "/Applications/VLC.app" ]]; then
    for type in public.movie public.mpeg-4 public.avi com.apple.quicktime-movie public.mpeg; do
        run duti -s org.videolan.vlc "$type" all
    done
else
    failures+=("VLC associations: install duti and VLC with script 1")
fi

# Dock and Mission Control. See the Sequoia demos linked in README.md.
run defaults write com.apple.dock mineffect -string scale
run defaults write com.apple.dock minimize-to-application -bool true
run defaults write com.apple.dock mru-spaces -bool false
run defaults write com.apple.dock show-recents -bool false
run defaults write com.apple.dock launchanim -bool false
run defaults write com.apple.dock autohide-delay -float 0
run defaults write com.apple.dock autohide-time-modifier -float 0.15
run defaults write com.apple.dock wvous-br-corner -int 4
run defaults write com.apple.dock wvous-br-modifier -int 0
run defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false

# Sequoia stores the percentage preference in the current-host domain.
if [[ "${macos_version%%.*}" -eq 15 ]]; then
    run defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true
fi

# Keyboard and trackpad. These are user preferences, not login-screen settings.
run defaults write -g ApplePressAndHoldEnabled -bool false
run defaults write -g KeyRepeat -int 1
run defaults write -g InitialKeyRepeat -int 10
run defaults write -g NSAutomaticQuoteSubstitutionEnabled -bool false
run defaults write -g NSAutomaticDashSubstitutionEnabled -bool false
run defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false
run defaults write -g NSAutomaticWindowAnimationsEnabled -bool false
for domain in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do
    run defaults write "$domain" Clicking -bool true
    # Other drag modes conflict with three-finger drag.
    run defaults write "$domain" Dragging -bool false
    run defaults write "$domain" DragLock -bool false
    run defaults write "$domain" TrackpadThreeFingerDrag -bool true
done
run defaults -currentHost write -g com.apple.mouse.tapBehavior -int 1
run defaults write -g com.apple.mouse.tapBehavior -int 1

echo "Configuring Finder..."
run defaults write com.apple.finder QuitMenuItem -bool true
run defaults write com.apple.finder NewWindowTarget -string PfHm
run defaults write com.apple.finder ShowStatusBar -bool true
run defaults write com.apple.finder FXDefaultSearchScope -string SCcf
run defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
run defaults write com.apple.finder FXPreferredViewStyle -string Nlsv
run defaults write com.apple.finder WarnOnEmptyTrash -bool false
run defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
run defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
run defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
run defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
run defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
run defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true
run chflags nohidden "$HOME/Library"

run defaults write com.apple.ActivityMonitor OpenMainWindow -bool true
run defaults write com.apple.ActivityMonitor IconType -int 5
run defaults write com.apple.ActivityMonitor ShowCategory -int 0
run defaults write com.apple.ActivityMonitor SortColumn -string CPUUsage
run defaults write com.apple.ActivityMonitor SortDirection -int 0
run defaults write -g NSNavPanelExpandedStateForSaveMode -bool true
run defaults write -g NSNavPanelExpandedStateForSaveMode2 -bool true
run defaults write -g PMPrintingExpandedStateForPrint -bool true
run defaults write -g PMPrintingExpandedStateForPrint2 -bool true
run defaults write com.apple.screencapture include-date -bool false
if run mkdir -p "$HOME/Desktop/Screenshots"; then
    run defaults write com.apple.screencapture location -string "$HOME/Desktop/Screenshots"
fi

# These system settings require authentication. Skip pmset on desktop Macs.
if run sudo -v; then
    # Intentional: remove global local account policies to allow shorter passwords.
    run sudo pwpolicy -clearaccountpolicies
    run sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo -string HostName
    if pmset -g batt | grep -q 'InternalBattery'; then
        run sudo pmset -b displaysleep 20
    fi
fi

# Use PHP itself to find the ini file (including paths containing spaces).
if command -v php >/dev/null 2>&1; then
    if config_file=$(php -r 'echo php_ini_loaded_file();') && [[ -f "$config_file" ]]; then
        backup_file="$config_file.before-macos-setup"
        if [[ -e "$backup_file" ]] || run cp "$config_file" "$backup_file"; then
            if run sed -i '' \
                -e 's/^[[:space:]]*max_execution_time[[:space:]]*=.*/max_execution_time = 600/' \
                -e 's/^[[:space:]]*memory_limit[[:space:]]*=.*/memory_limit = 1024M/' \
                -e 's/^[[:space:]]*upload_max_filesize[[:space:]]*=.*/upload_max_filesize = 512M/' \
                -e 's/^[[:space:]]*post_max_size[[:space:]]*=.*/post_max_size = 512M/' "$config_file"; then
                # CLI PHP forces execution time to 0; inspect that saved directive.
                # Check the other limits for overrides in additional ini files.
                run php -r '$ini = parse_ini_file(php_ini_loaded_file(), false, INI_SCANNER_RAW); exit(($ini["max_execution_time"] ?? "") == "600" && ini_get("memory_limit") == "1024M" && ini_get("upload_max_filesize") == "512M" && ini_get("post_max_size") == "512M" ? 0 : 1);'
            fi
        fi
    else
        failures+=("PHP did not report an existing loaded php.ini")
    fi
else
    failures+=("PHP configuration: install PHP with script 1")
fi

run git config --global user.email "mzgsdev@gmail.com"
run git config --global user.name "Mustafa"

# Validate all targets before clearing the Dock; batch changes into one restart.
dock_apps=(
    "/System/Applications/Mail.app"
    "/Applications/Google Chrome.app"
    "/System/Applications/System Settings.app"
    "/Applications/Visual Studio Code.app"
)
dock_ready=true
if ! command -v dockutil >/dev/null 2>&1; then
    failures+=("Dock configuration: install dockutil with script 1")
    dock_ready=false
fi
for app in "${dock_apps[@]}" "$HOME/Downloads"; do
    if [[ ! -d "$app" ]]; then
        failures+=("Dock target missing: $app")
        dock_ready=false
    fi
done
if [[ "$dock_ready" == true ]] && run dockutil --remove all --no-restart; then
    for app in "${dock_apps[@]}"; do
        run dockutil --add "$app" --no-restart
    done
    run dockutil --add "$HOME/Downloads" --view fan --display stack --sort dateadded --section others --no-restart
fi

# A process not running is normal; do not count that as a setup failure.
for process in Finder Dock SystemUIServer ControlCenter; do
    if pgrep -x "$process" >/dev/null; then
        run killall "$process"
    fi
done

cat <<'EOF'

Manual settings / verification after logging out and back in:
  - Control Center (macOS 15), or Menu Bar on newer macOS: show Battery percentage
    and Sound; use Clock Options for the date, day of week, and 24-hour clock.
  - Accessibility > Pointer Control > Trackpad Options: verify Three Finger Drag.
  - Accessibility > Zoom: enable scroll-to-zoom with Control and focus tracking.
  - Accessibility > Display: enable Reduce motion for animations still present.
  - General > Software Update > Automatic Updates: choose your update preferences.
  - Apple Intelligence & Siri: turn Siri off if desired.
  - Lock Screen: choose your password delay (the old script requested 8 hours).
  - Privacy & Security: use Open Anyway individually for trusted blocked apps.
  - Notifications: configure permissions per app; no global prompt bypass is used.
  - Image Capture: select each device and set "Connecting this device opens" to
    "No application" to prevent Photos opening automatically.
Legacy Help Viewer, Quick Look selection, Bluetooth bitpool, Time Machine disk
prompts, and app-specific hidden tweaks were omitted; see README.md.
EOF

if [[ "${#failures[@]}" -gt 0 ]]; then
    printf '\nSettings setup finished with %s failure(s):\n' "${#failures[@]}" >&2
    printf '  - %s\n' "${failures[@]}" >&2
    exit 1
fi
echo "Preference commands completed. Log out/in, then verify the manual settings above."
