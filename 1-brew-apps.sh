

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Keep Homebrew installs automated.
export NONINTERACTIVE=1
export PIP_NO_INPUT=1

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Function to check if a command was successful
check_status() {
    if [ $? -eq 0 ]; then
        print_status "$1 successful"
    else
        print_error "$1 failed"
        return 1
    fi
}

# Start installation
echo "========================================="
echo "Starting macOS Setup Script"
echo "========================================="

 
# Check if Homebrew is already installed
if ! command -v brew &> /dev/null; then
    print_status "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Determine the correct Homebrew path based on architecture
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        BREW_PREFIX="/opt/homebrew"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        BREW_PREFIX="/usr/local"
    else
        print_error "Could not find Homebrew installation"
        exit 1
    fi
    
    # Add Homebrew to PATH for current session
    eval "$($BREW_PREFIX/bin/brew shellenv)"
    
    # Add Homebrew to shell profile
    SHELL_PROFILE="$HOME/.zprofile"
    if [[ ! -f "$SHELL_PROFILE" ]]; then
        touch "$SHELL_PROFILE"
    fi
    
    if ! grep -q "brew shellenv" "$SHELL_PROFILE"; then
        echo '' >> "$SHELL_PROFILE"
        echo 'eval "$('$BREW_PREFIX'/bin/brew shellenv)"' >> "$SHELL_PROFILE"
        print_status "Added Homebrew to $SHELL_PROFILE"
    fi
    
    # Source the profile
    source "$SHELL_PROFILE"
else
    print_status "Homebrew is already installed"
    yes | brew update
fi

# Verify Homebrew is working
if ! command -v brew &> /dev/null; then
    print_error "Homebrew installation failed or not in PATH"
    exit 1
fi

print_status "Homebrew is ready"

# CLI Tools
echo ""
echo "========================================="
echo "Installing CLI Tools"
echo "========================================="

CLI_APPS=(
    "wget"
    "speedtest-cli"
    "dockutil"
    "tree"
    "node"
    "go"
    "bash-completion@2"
    "ncdu"
    "duti"
    "php"
    "mariadb"
    "phpmyadmin"
    "ffmpeg"
    "composer"
)

for app in "${CLI_APPS[@]}"; do
    if brew list "$app" &>/dev/null; then
        print_warning "$app is already installed"
    else
        print_status "Installing $app..."
        if yes | brew install "$app" 2>/dev/null; then
            print_status "$app installed successfully"
        else
            print_error "Failed to install $app"
        fi
    fi
done

# Cask Applications
echo ""
echo "========================================="
echo "Installing Cask Applications"
echo "========================================="

CASK_APPS=(
    "the-unarchiver"
    "google-chrome"
    "appcleaner"
    "raycast"
    "android-studio"
    "handbrake"
    "vlc"
    "rapidapi"
    "cyberduck"
    "visual-studio-code"
    "telegram"
    "tinypng4mac"
    "whatsapp"
)

for app in "${CASK_APPS[@]}"; do
    if brew list --cask "$app" &>/dev/null; then
        print_warning "$app is already installed"
    else
        print_status "Installing $app..."
        if yes | brew install --cask "$app" 2>/dev/null; then
            print_status "$app installed successfully"
        else
            print_error "Failed to install $app (might require manual installation)"
        fi
    fi
done


yes | "$(brew --prefix python@3.10)/bin/python3.10" -m pip install --upgrade --no-input yt-dlp

# Start MariaDB service
echo ""
echo "========================================="
echo "Starting Services"
echo "========================================="

if brew services list | grep -q "mariadb.*started"; then
    print_status "MariaDB service is already running"
else
    print_status "Starting MariaDB service..."
    if yes | brew services start mariadb; then
        print_status "MariaDB service started"
    else
        print_error "Failed to start MariaDB service"
    fi
fi

# Clean up
echo ""
print_status "Cleaning up Homebrew cache..."
yes | brew cleanup

# Summary
echo ""
echo "========================================="
echo "Installation Summary"
echo "========================================="

# Check installed CLI apps
echo ""
echo "Installed CLI tools:"
for app in "${CLI_APPS[@]}"; do
    if brew list "$app" &>/dev/null; then
        echo "  ✓ $app"
    else
        echo "  ✗ $app (not installed)"
    fi
done

# Check installed Cask apps
echo ""
echo "Installed Cask applications:"
for app in "${CASK_APPS[@]}"; do
    if brew list --cask "$app" &>/dev/null; then
        echo "  ✓ $app"
    else
        echo "  ✗ $app (not installed)"
    fi
done

 
