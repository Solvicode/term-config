#!/bin/bash

# color codes for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# fuction to print colored output
print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_error() {
    echo -e "${RED}[-]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# check if running as root
if [ "$EUID" -eq 0 ]; then 
    print_error "Please do not run as root"
    exit 1
fi

# welcome message
clear
print_status "
 ___  _____  __  _  _  ____  ___  _____  ____  ____ 
/ __)(  _  )(  )( \/ )(_  _)/ __)(  _  )(  _ \( ___)
\__ \ )(_)(  )(__\  /  _)(_( (__  )(_)(  )(_) ))__) 
(___/(_____)(____)\/  (____)\___)(_____)(____/(____)
"
print_status "This script will set up your terminal environment based on the Solvicode configuration"
echo

# check for existing configuration
if [ -f ~/.zshrc ]; then
    print_warning "Existing ~/.zshrc configuration detected!"
    print_warning "Your current configuration will be preserved at ~/.zshrc_user"
    print_warning "You can refer to it later to copy over any custom configurations you had"
    echo
    read -p "Would you like to continue? (y/N): " continue_setup
    if [[ ! $continue_setup =~ ^[Yy]$ ]]; then
        print_status "Setup cancelled by user"
        exit 0
    fi
    cp ~/.zshrc ~/.zshrc_user
    print_success "Existing configuration backed up to ~/.zshrc_user"
fi


# create necessary directories
print_status "Creating directory structure..."
mkdir -p ~/git/solvicode/term-config

# install required packages
print_status "Installing required packages..."
sudo apt update
sudo apt-get install -y curl git zsh zsh-autosuggestions zsh-syntax-highlighting build-essential curl libbz2-dev libffi-dev liblzma-dev libncursesw5-dev libreadline-dev libsqlite3-dev libssl-dev libxml2-dev libxmlsec1-dev llvm make tk-dev wget xz-utils zlib1g-dev

# install Oh My Zsh
print_status "Installing Oh My Zsh..."
if [ -d ~/.oh-my-zsh ]; then
    print_status "Oh My Zsh is already installed, skipping..."
else
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# install Oh My Zsh plugins
print_status "Installing Oh My Zsh plugins..."
git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 2>/dev/null || true
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 2>/dev/null || true

# create and setup private environment variables
print_status "Setting up private environment variables..."
if [ -f ~/.private_envs ]; then
    print_warning "Existing ~/.private_envs file found!"
    print_warning "Current file will be backed up to ~/.private_envs.backup"
    cp ~/.private_envs ~/.private_envs.backup
    
    # check if GitHub credentials already exist in the file
    if grep -q "GITHUB_USER\|GITHUB_TOKEN" ~/.private_envs; then
        print_warning "GitHub credentials already exist in ~/.private_envs"
        read -p "Would you like to update them? (y/N): " update_creds
        if [[ $update_creds =~ ^[Yy]$ ]]; then
            # prompt for GitHub credentials
            read -p "Enter your GitHub username: " GITHUB_USER
            read -sp "Enter your GitHub token: " GITHUB_TOKEN
            echo

            # remove existing GitHub credentials and add new ones
            sed -i '/GITHUB_USER/d' ~/.private_envs
            sed -i '/GITHUB_TOKEN/d' ~/.private_envs
            echo "export GITHUB_USER=\"${GITHUB_USER}\"" >> ~/.private_envs
            echo "export GITHUB_TOKEN=\"${GITHUB_TOKEN}\"" >> ~/.private_envs
        fi
    else
        # prompt for GitHub credentials
        read -p "Enter your GitHub username: " GITHUB_USER
        read -sp "Enter your GitHub token: " GITHUB_TOKEN
        echo

        # add new GitHub credentials
        echo "export GITHUB_USER=\"${GITHUB_USER}\"" >> ~/.private_envs
        echo "export GITHUB_TOKEN=\"${GITHUB_TOKEN}\"" >> ~/.private_envs
    fi
else
    # prompt for GitHub credentials
    read -p "Enter your GitHub username: " GITHUB_USER
    read -sp "Enter your GitHub token: " GITHUB_TOKEN
    echo

    # create new file if it doesn't exist
    cat > ~/.private_envs << EOL
export GITHUB_USER="${GITHUB_USER}"
export GITHUB_TOKEN="${GITHUB_TOKEN}"
EOL
fi

chmod 600 ~/.private_envs

# create zshrc configuration
print_status "Fetching zsh configuration from repository..."
curl -o ~/git/solvicode/term-config/.zshrc https://raw.githubusercontent.com/Solvicode/term-config/main/.zshrc

# create symbolic link for zshrc
print_status "Creating symbolic links..."
ln -sf ~/git/solvicode/term-config/.zshrc ~/.zshrc

# Optional installations
print_status "Would you like to install the following tools?"
print_status ""

read -p "Install Pyenv? (y/N): " install_pyenv
if [[ $install_pyenv =~ ^[Yy]$ ]]; then
    curl https://pyenv.run | bash
fi

read -p "Install Poetry? (y/N): " install_poetry
if [[ $install_poetry =~ ^[Yy]$ ]]; then
    curl -sSL https://install.python-poetry.org | python3 -
fi

read -p "Install NVM? (y/N): " install_nvm
if [[ $install_nvm =~ ^[Yy]$ ]]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi

read -p "Install Bun? (y/N): " install_bun
if [[ $install_bun =~ ^[Yy]$ ]]; then
  curl -fsSL https://bun.sh/install | bash
fi

# Set zsh as default shell
print_status "Setting zsh as default shell..."
if [[ $SHELL != *"zsh"* ]]; then
    chsh -s $(which zsh) $USER
fi

print_success "Installation complete!"
print_success "Please log out and log back in for all changes to take effect."
print_warning "Your previous zsh configuration has been saved to ~/.zshrc_user"
print_warning "You may want to review it and copy over any custom configurations you had"
print_status "After logging back in, you may want to install additional tools like Go, Pulumi, etc."
