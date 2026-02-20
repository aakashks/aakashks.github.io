#!/usr/bin/env bash
set -euo pipefail

# Configuration
CONFIG_BASE_URL="https://aakashks.github.io/setup"
BIN_DIR="$HOME/.local/bin"
CHISEL_VERSION="1.10.1" # Update this to the latest release as needed

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Cleanup on interrupt
cleanup() {
	echo -e "\n${YELLOW}Installation interrupted...${NC}"
	exit 1
}

trap cleanup INT TERM

log() { echo -e "${BLUE}[INFO]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1" >&2; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

# 1. System Packages & Dependencies
install_system_packages() {
	log "Updating package lists and installing system dependencies..."
	
	# Try to use sudo if available/needed
	local SUDO=""
	if command_exists sudo; then
		SUDO="sudo"
	fi

	$SUDO apt-get update -y
	
	$SUDO apt-get install -y \
		curl wget git tmux aria2 jq unzip \
		build-essential htop net-tools
		
	success "System packages installed."
}

# 2. Custom Binaries (Chisel)
install_binaries() {
	log "Installing custom binaries to $BIN_DIR..."
	mkdir -p "$BIN_DIR"

	if ! command_exists chisel; then
		log "Downloading Chisel v${CHISEL_VERSION}..."
		local CHISEL_URL="https://github.com/jpillora/chisel/releases/download/v${CHISEL_VERSION}/chisel_${CHISEL_VERSION}_linux_amd64.gz"
		
		curl -fsSL "$CHISEL_URL" | gzip -d > "$BIN_DIR/chisel"
		chmod +x "$BIN_DIR/chisel"
		success "Chisel installed."
	else
		log "Chisel already installed, skipping."
	fi
}

# 3. Dotfiles & Configs
setup_dotfiles() {
	log "Configuring tmux..."
	cat > "$HOME/.tmux.conf" << 'EOF'
# Custom Tmux Configuration
set -g mouse on
set -g default-terminal "screen-256color"
set -g history-limit 100000
set-option -g set-clipboard on

# Optional: Add better split shortcuts
bind | split-window -h
bind - split-window -v
EOF

	log "Configuring bash aliases..."
	cat > "$HOME/.bash_aliases" << 'EOF'
alias ll='ls -hAlF'

PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

tmx() {
    if [ -n "$1" ]; then
        if tmux has-session -t "$1" 2>/dev/null; then
            tmux -u -CC attach -t "$1"
        else
            tmux -u -CC new-session -s "$1"
        fi
    else
        tmux -u -CC
    fi
}

extract () {
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)   tar xjf $1   ;;
      *.tar.gz)    tar xzf $1   ;;
      *.tar.xz)    tar xf $1   ;;
      *.tar.lrz)   lrztar -d $1 ;; 
      *.bz2)       bunzip2 $1   ;;
      *.rar)       unrar x $1   ;;
      *.gz)        gunzip $1    ;;
      *.tar)       tar xf $1    ;;
      *.tbz2)      tar xjf $1   ;;
      *.tgz)       tar xzf $1   ;;
      *.zip)       unzip $1     ;;
      *.Z)         uncompress $1;;
      *.7z)        7z x $1      ;;
      *)           echo "'$1' cannot be extracted with ex" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}
EOF

	log "Setting up VS Code settings..."
	mkdir -p "$HOME/.vscode"
	# Fetch from your hosted GitHub Pages
	if curl -fI "$CONFIG_BASE_URL/settings.json" >/dev/null 2>&1; then
		curl -fsSL "$CONFIG_BASE_URL/settings.json" -o "$HOME/.vscode/settings.json"
		success "VS Code settings downloaded."
	else
		warn "Could not fetch settings.json from $CONFIG_BASE_URL. Creating a default."
		cat > "$HOME/.vscode/settings.json" << 'EOF'
{
    "files.watcherExclude": {
        "**/.git/**": true,
        "**/node_modules/**": true,
        "**/.conda/**": true,
        "**/.mamba/**": true,
        "**/.venv/**": true,
        "**/venv/**": true,
        "**/env/**": true,
        // ML-specific heavy dirs
        "**/data/**": true,
        "**/datasets/**": true,
        "**/checkpoints/**": true,
        "**/logs/**": true,
        "**/wandb/**": true,
        "**/outputs/**": true,
        "**/runs/**": true,
        "**/tmp/**": true,
        // Model artifacts
        "**/*.pt": true,
        "**/*.pth": true,
        "**/*.ckpt": true,
        "**/*.bin": true,
        "**/*.safetensors": true,
        "**/__pycache__/**": true,
    },
    // Faster search
    "search.exclude": {
        "**/data/**": true,
        "**/datasets/**": true,
        "**/checkpoints/**": true,
        "**/wandb/**": true,
        "**/outputs/**": true,
        "**/runs/**": true,
        "**/tmp/**": true,
        "**/__pycache__": true
    },
    "files.autoSave": "afterDelay",
    "terminal.integrated.profiles.linux": {
        "tmux": {
            "path": "bash",
            "args": [
                "-c",
                "tmux new -ADs aks bash"
            ],
            "icon": "terminal-tmux"
        }
    },
    // "terminal.integrated.defaultProfile.linux": "tmux"
    "editor.fontSize": 12,
    "files.associations": {
        "array": "cpp",
        "string_view": "cpp",
        "initializer_list": "cpp",
        "utility": "cpp"
    },
    "[python]": {
        "editor.defaultFormatter": "charliermarsh.ruff",
        "editor.codeActionsOnSave": {
            "source.organizeImports": "always"
        }
    },
    "python.languageServer": "Pylance",
    "python.analysis.exclude": [
        "**/data/**",
        "**/datasets/**",
        "**/checkpoints/**",
        "**/wandb/**",
        "**/outputs/**",
        "**/runs/**",
        "**/tmp/**",
    ],
    "python.analysis.diagnosticMode": "openFilesOnly",
    "python.analysis.inlayHints.variableTypes": false,
    "python.analysis.typeCheckingMode": "off",
    "python.analysis.autoImportCompletions": false,
    // Massive speedup on remote
    "python.analysis.stubPath": "",
    "python.analysis.userFileIndexingLimit": 2000,
    // "editor.defaultFoldingRangeProvider": "astral-sh.ty",
    "notebook.defaultFormatter": "charliermarsh.ruff",
    "ruff.showSyntaxErrors": false,
    "ruff.lint.enable": true,
    // "editor.fontFamily": "JetBrainsMono Nerd Font Mono"
}
EOF
	fi
	
	log "Configuring global Git settings..."
	git config --global user.name "aakash"
	# git config --global user.email "114357454+aakashks@users.noreply.github.com"
	git config --global core.editor "nano"
}

# 4. GitHub Credentials (.netrc)
setup_github_auth() {
	if [ -f "$HOME/.netrc" ]; then
		warn ".netrc already exists."
		return
    else
        warn "No .netrc file found. Make sure to set up GitHub authentication manually."
	fi

# 	echo -e "\n${BLUE}--- GitHub Authentication ---${NC}"
# 	echo "To clone private repositories, you need a Personal Access Token (PAT)."
# 	echo "Leave blank to skip."
	
# 	read -p "Enter GitHub Username: " github_user
	
# 	if [ -n "$github_user" ]; then
# 		# Use -s to hide the token input
# 		read -s -p "Enter GitHub PAT (starts with ghp_): " github_token
# 		echo ""
		
# 		if [ -n "$github_token" ]; then
# 			cat > "$HOME/.netrc" << EOF
# machine github.com
# login $github_user
# password $github_token
# EOF
# 			chmod 600 "$HOME/.netrc"
# 			success "GitHub credentials saved securely to ~/.netrc"
# 		else
# 			warn "No token provided. Skipping .netrc setup."
# 		fi
# 	else
# 		log "Skipping GitHub auth setup."
# 	fi
#	echo -e "${BLUE}-----------------------------${NC}\n"
}

# 5. Environment Variables & PATH
update_path() {
	log "Updating PATH in .bashrc..."
	
	local PATH_STRING='export PATH="$PATH:$HOME/.local/bin:$HOME/bin:$HOME/go/bin:$HOME/.cargo/bin"'
	
	if grep -q "HOME/.local/bin" "$HOME/.bashrc"; then
		log "PATH already seems to be configured in .bashrc."
	else
		echo -e "\n# Custom Workspace PATH\n$PATH_STRING" >> "$HOME/.bashrc"
		success "PATH updated in .bashrc"
	fi
}

# Main Execution
main() {
	log "Starting Workspace Setup..."

	install_system_packages
	install_binaries
	setup_dotfiles
	update_path
	setup_github_auth

	echo ""
	success "Workspace setup complete!"
	log "Please run 'source ~/.bashrc' or restart your shell to apply changes."
}

main "$@"