#!/bin/bash
# Keep going if one setting is unsupported, an app is missing, or a command fails.
set +e
echo "Starting MacOS setup script for fresh install."



sudo spctl --master-disable
 
duti -s org.videolan.vlc public.movie all
duti -s org.videolan.vlc public.mpeg-4 all
duti -s org.videolan.vlc public.avi all
duti -s org.videolan.vlc com.apple.quicktime-movie all
duti -s org.videolan.vlc public.mpeg all



# Settings
echo "Applying macOS settings..."
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
defaults write com.apple.helpviewer DevMode -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
echo "General macOS settings applied."



defaults write com.apple.dock show-recents -bool false


# Dock preferences
echo "Configuring Dock preferences..."
defaults write com.apple.dock mineffect -string "scale"
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock mru-spaces -bool false
defaults write com.apple.dock show-recents -bool false
echo "Dock preferences configured."

# Show battery percentage
defaults write com.apple.controlcenter "NSStatusItem Visible Battery" -bool true
defaults write com.apple.controlcenter "Battery ShowPercentage" -bool true

# Prevent Photos from opening automatically when devices are plugged in
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

# Trackpad and input preferences
echo "Configuring trackpad and keyboard preferences..."
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write -g com.apple.mouse.tapBehavior -int 1
defaults write -g com.apple.mouse.tapBehavior -int 1
defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool true
defaults write com.apple.universalaccess HIDScrollZoomModifierMask -int 262144
defaults write com.apple.universalaccess closeViewZoomFollowsFocus -bool true
defaults write -g ApplePressAndHoldEnabled -bool false
defaults write -g KeyRepeat -int 1
defaults write -g InitialKeyRepeat -int 10
echo "Trackpad and keyboard preferences configured."
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10

# Disable animations when opening and closing windows
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
# Speed up Mission Control animations
defaults write com.apple.dock expose-animation-duration -float 0.1
# Don't animate opening applications from the Dock
defaults write com.apple.dock launchanim -bool false

 

# Show IP address, hostname, OS version when clicking clock in login screen
sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName


defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false

sudo pmset -b displaysleep 20

# Finder preferences
echo "Configuring Finder preferences..."
defaults write com.apple.finder QuitMenuItem -bool true
defaults write com.apple.finder NewWindowTarget -string "PfHm"
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
chflags nohidden ~/Library
defaults write com.apple.dock wvous-br-corner -int 4 && defaults write com.apple.dock wvous-br-modifier -int 0
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.15
defaults write com.apple.dock mineffect -string scale
defaults write com.apple.dock show-recents -bool false

killall Dock

echo "Finder preferences configured."

# Time Machine preferences
echo "Configuring Time Machine preferences..."
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
echo "Time Machine preferences configured."

# Activity Monitor preferences
echo "Configuring Activity Monitor preferences..."
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true
defaults write com.apple.ActivityMonitor IconType -int 5
defaults write com.apple.ActivityMonitor ShowCategory -int 0
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0
echo "Activity Monitor preferences configured."

# Show icons for hard drives, servers, and removable media on desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# Speed up window resize animations
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

# Improve Bluetooth audio quality
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40
# Telegram - Disable animations
defaults write ru.keepcoder.Telegram reduceMotion -bool true


# QuickTime Player preferences
echo "Configuring QuickTime Player preferences..."
defaults write com.apple.QuickTimePlayerX MGPlayMovieOnOpen -bool true
echo "QuickTime Player preferences configured."

# Software update preferences
echo "Disabling automatic software update checks..."
sudo softwareupdate --schedule off
echo "Automatic software updates disabled."

# Save and print panels
echo "Expanding save and print panels by default..."
defaults write -g NSNavPanelExpandedStateForSaveMode -bool true
defaults write -g PMPrintingExpandedStateForPrint -bool true
echo "Save and print panel settings applied."

# Security and input tweaks
echo "Applying security and input tweaks..."
sudo pwpolicy -clearaccountpolicies
defaults write com.apple.CrashReporter DialogType -string "none"
defaults write -g NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write -g NSAutomaticDashSubstitutionEnabled -bool false
defaults write com.apple.ncprefs.plist DoNotPromptForNotifications -bool true && killall NotificationCenter
defaults write com.apple.dock showAppExposeGestureEnabled -bool true
defaults write com.apple.menuextra.clock DateFormat -string "EEE d MMM HH:mm"
defaults write com.apple.systemuiserver "NSStatusItem Visible com.apple.menuextra.volume" -bool true
defaults write com.apple.screencapture include-date -bool false
mkdir -p ~/Desktop/Screenshots
defaults write com.apple.screencapture location -string "${HOME}/Desktop/Screenshots"
defaults write com.apple.finder QLEnableTextSelection -bool true
defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false
defaults write com.apple.assistant.support "Assistant Enabled" -bool false && killall ControlCenter
echo "Security and input tweaks applied."

osascript -e 'tell application "System Events" to key code 144'

# Enable tap to click for current user
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true

# Enable tap to click for login screen
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Enable three-finger drag
 defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
# Alternative method for three-finger drag (Accessibility setting)
defaults write com.apple.accessibility.mouse TrackpadThreeFingerDrag -bool true

# Set 8-hour delay (28800 seconds) before password is required
defaults write com.apple.screensaver askForPasswordDelay -int 28800

# Keep password requirement enabled but with 8-hour delay
defaults write com.apple.screensaver askForPassword -int 1

# php config
config_file=$(php --ini | awk '/Loaded Configuration File/ {print $4}')
sudo sed -i '' -e 's/^max_execution_time = .*/max_execution_time = 600/' \
               -e 's/^memory_limit = .*/memory_limit = 1024M/' \
               -e 's/^upload_max_filesize = .*/upload_max_filesize = 512M/' \
               -e 's/^post_max_size = .*/post_max_size = 512M/' "$config_file"


# Git configuration
echo "Configuring Git..."
git config --global user.email "mzgsdev@gmail.com"
git config --global user.name "Mustafa"
echo "Git configuration complete."

defaults write com.apple.dock wvous-br-corner -int 4; defaults write com.apple.dock wvous-br-modifier -int 0;
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false
defaults write com.apple.finder WarnOnEmptyTrash -bool false


dockutil --remove all

dockutil --add /Applications/Mail.app
dockutil --add /Applications/Google\ Chrome.app
dockutil --add /System/Applications/System\ Settings.app
dockutil --add "/Applications/Visual Studio Code.app"
dockutil --add /Users/$(whoami)/Downloads --view fan --display stack --sort dateadded --section others

python3 -m pip config set global.break-system-packages true
python3 -m pip config set install.user true

 
# Restart services
echo "Restarting Finder, Dock, and SystemUIServer..."
killall Finder
killall Dock
killall cfprefsd

echo "Finished installations and configurations."
exit 0
