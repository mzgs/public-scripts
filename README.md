# public-scripts


## Install VPN + PROXY 

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/mzgs/public-scripts/main/wireguard_vpn.sh) && \
bash <(curl -fsSL https://raw.githubusercontent.com/mzgs/public-scripts/main/squid_proxy.sh)
```
 
## Install wireguard vpn  
```
bash <(curl -fsSL https://raw.githubusercontent.com/mzgs/public-scripts/main/wireguard_vpn.sh)
```

## Install Squid Proxy  
```
bash <(curl -fsSL https://raw.githubusercontent.com/mzgs/public-scripts/main/squid_proxy.sh)
```


## macOS 15+ setup

Run both scripts as your normal user, without `sudo`. Script 1 requests your
administrator password when installing Homebrew; script 2 requests it to clear
global local account policies and set login-window and battery sleep preferences.
Open a new terminal after script 1.
Close System Settings and the apps whose preferences you want to change before
running script 2. Log out and back in afterward.

Both scripts continue after individual failures, show the original error and a
failure summary, and exit with status 1 when something fails. They do not promise
that writing an undocumented `defaults` key makes every macOS release honor it.

#### Apps 
```
bash <(curl -fsSL https://raw.githubusercontent.com/mzgs/public-scripts/main/1-brew-apps.sh)
```

#### Mac Settings 
```
bash <(curl -fsSL https://raw.githubusercontent.com/mzgs/public-scripts/main/2-mac-settings.sh)
```

### Installation changes

- yt-dlp is installed through [Homebrew](https://formulae.brew.sh/formula/yt-dlp),
  without a hardcoded Python version or global pip overrides.
- [TinyPNG4Mac](https://formulae.brew.sh/cask/tinypng4mac) is omitted because
  Homebrew disabled it for failing Gatekeeper checks.
- [speedtest-go](https://formulae.brew.sh/formula/speedtest-go) replaces the
  deprecated speedtest-cli. An existing speedtest-cli is unlinked, not removed,
  to avoid their shared `speedtest` executable conflicting.
- HandBrake uses the current `handbrake-app` cask token; Codex uses its cask.
- ffmpeg-full is keg-only, so its bin directory is added to your shell profile.
  The script adds Homebrew's environment without sourcing a zsh profile in Bash.
- Applications can impose additional architecture or OS requirements. Homebrew
  reports these errors instead of the script hiding them.

### Preferences and manual settings

Dock delay, animation time, minimize effect, recents, Finder status bar, and
Mission Control space ordering have [Sequoia demonstrations](https://macos-defaults.com/).
The battery-percentage command uses the current-host `BatteryShowPercentage`
key from a [Sequoia setup](https://gist.github.com/marlosirapuan/08827a957f7c6219721956930c1897d2).
It is only written on macOS 15; verify the corresponding UI on newer releases.
Trackpad settings are written to the built-in and Bluetooth domains, with other
drag modes disabled. Verify them after logging out and back in.

The script prints this checklist instead of pretending that old hidden keys
configure these settings reliably:

| Preference | Manual location/action |
| --- | --- |
| Battery, Sound, clock date/day and 24-hour time | Control Center on macOS 15; Menu Bar on newer macOS. Use Clock Options and General > Date & Time / Language & Region as needed. |
| Three-finger dragging | Accessibility > Pointer Control > Trackpad Options: enable dragging and choose Three Finger Drag. [Apple instructions](https://support.apple.com/en-us/102341). |
| Control-scroll zoom and focus tracking | Accessibility > Zoom. [Apple instructions](https://support.apple.com/guide/mac-help/change-zoom-settings-for-accessibility-mh40579/mac). |
| Remaining window animations | Accessibility > Display > Reduce motion. |
| Automatic update checks/downloads/installations | General > Software Update > Automatic Updates. The obsolete `softwareupdate --schedule off` command is omitted. [Apple instructions](https://support.apple.com/en-gb/guide/mac-help/mchla7037245/mac). |
| Siri | Apple Intelligence & Siri: turn Siri off if desired. |
| Password delay | Lock Screen: choose the desired delay. The old script requested 8 hours. |
| Trusted blocked applications | Privacy & Security > Open Anyway for the individual app. No global Gatekeeper disable. [Apple instructions](https://support.apple.com/en-us/102445). |
| Notifications | Configure permissions per app in Notifications; no undocumented global prompt bypass. |
| Photos opening when devices connect | Image Capture: select the device, show device options, set "Connecting this device opens" to "No application". |

Removed legacy writes include `NSWindowResizeTime`, Help Viewer's `DevMode`,
Quick Look's `QLEnableTextSelection`, Bluetooth audio bitpool, custom clock
`DateFormat`, Time Machine's new-disk prompt suppression, and hidden Mail,
Telegram, QuickTime, and CrashReporter preferences. These lack reliable macOS
15+ verification; some are listed as broken or uncertain by the
[macOS defaults maintainers](https://github.com/yannbertrand/macos-defaults/blob/main/broken.md).
Use each app's settings where it offers an equivalent. Quick Look text selection,
the Bluetooth bitpool override, and the Help Viewer tweak have no verified
replacement in these scripts.

Password-policy clearing is intentional: script 2 runs
`sudo pwpolicy -clearaccountpolicies`, restoring the original behavior. This
removes global local account policies for all users so those rules do not impose
a minimum password length. Account-specific rules or device-management policies
may still impose restrictions; this command alone does not guarantee that every
Mac will accept a one-character password.

The Dock is rebuilt only when every target exists. Mail uses
`/System/Applications/Mail.app`. PHP's loaded ini file is backed up once as
`php.ini.before-macos-setup` before editing; restart your PHP application/server
to pick up its limits. The script checks the saved execution-time directive and
PHP CLI's effective memory/upload/post limits (CLI [overrides execution time](https://www.php.net/manual/en/features.commandline.differences.php)), reporting missing directives or
overrides. Verify your web server/FPM configuration separately if it uses a
different ini file. Git identity is still set to Mustafa / mzgsdev@gmail.com.

If an older run enabled pip overrides, inspect `python3 -m pip config debug` and
remove `global.break-system-packages` and `install.user` from the configuration
file that contains them if you no longer want them. Editing these scripts does
not undo settings or install/uninstall applications on your current Mac.

### Verification

```bash
bash -n 1-brew-apps.sh
bash -n 2-mac-settings.sh
python3 -B -m unittest discover -s tests -v
```

The tests use temporary homes and mocked system commands; they do not install
applications, modify your real preferences, or restart your desktop processes.
