#!/usr/bin/env bash

# William Stark (william.stark.5000@gmail.com)


# Exit immediately if a pipeline (which may consist of a single  simple  command),
# a list, or a compound command, exits with a non-zero status.
set -e


STANDARD_PACKAGES=(
    dos2unix
    hashdeep
    git
    python-argcomplete
    ripgrep
    ssh
    tmux
    xclip
)


yes_no_question() {
    while true; do
        read -e -p "$1 (y/n): " YES_NO_ANSWER < /dev/tty
        case $YES_NO_ANSWER in
            y)
                break
                ;;
            n)
                break
                ;;
            *)
                echo "Please enter \"y\" for yes or \"n\" for no." >&2
                ;;
        esac
    done

    echo $YES_NO_ANSWER
}


backup_datetime() {
    # append the suffix .backup and current datetime to a directory or file name

    TARGET="$1"
    DATE_TIME=$(date +%Y-%m-%d_%H:%M:%S%:z)

    if [[ -L "$TARGET" ]]; then
        echo "skipping symbolic link \"$TARGET\""
    elif [[ -d "$TARGET" ]] || [[ -f "$TARGET" ]]; then
        mv --interactive --verbose "$TARGET" "$TARGET.backup_$DATE_TIME"
    fi
}


create_data_directory() {
    sudo mkdir --parents --verbose /data

    sudo chown --verbose $SCRIPT_USER:$SCRIPT_USER /data

    # create symbolic link /d to /data
    sudo ln --symbolic --force --verbose /data /d
}


setup_python() {
    # https://www.python.org/

    # install pyenv
    # https://github.com/pyenv/pyenv
    if [[ -n "$PYENV_ROOT" ]]; then
        backup_datetime "$PYENV_ROOT"
    else
        PYENV_ROOT="$HOME/.pyenv"
        export "$PYENV_ROOT"
    fi
    # https://github.com/pyenv/pyenv-installer
    curl https://pyenv.run | bash

    # enable pyenv
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"

    # install xxenv-latest
    # https://github.com/momo-lab/xxenv-latest
    git clone https://github.com/momo-lab/xxenv-latest.git "$(pyenv root)"/plugins/xxenv-latest

    # install Python build dependencies
    # https://github.com/pyenv/pyenv/wiki#suggested-build-environment
    sudo apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

    PYTHON_LATEST_VERSION=$(pyenv latest --print)

    pyenv install $PYTHON_LATEST_VERSION
    pyenv global $PYTHON_LATEST_VERSION

    # upgrade global Python pip
    pip install --upgrade pip

    # install Poetry
    # https://github.com/python-poetry/poetry
    curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/install-poetry.py | python -

    # link $HOME/.pylintrc and .config/flake8
    ln --symbolic --force --verbose $HOME/dotfiles/.pylintrc $HOME/
    ln --symbolic --force --verbose $HOME/dotfiles/.config/flake8 $HOME/.config/
}


setup_python_programs() {
    # install pipx
    # https://github.com/pypa/pipx
    python3 -m pip install --user pipx
    python3 -m pipx ensurepath

    PIPX_BIN_DIR="$HOME/.local/bin"
    export PATH="$PIPX_BIN_DIR:$PATH"

    # https://github.com/psf/black
    pipx install black

    # https://github.com/ytdl-org/youtube-dl
    pipx install youtube-dl
}


setup_neovim() {
    # https://github.com/neovim/neovim

    backup_datetime $HOME/.config/nvim/init.vim

    # https://github.com/neovim/neovim/wiki/Installing-Neovim#ubuntu

    sudo add-apt-repository ppa:neovim-ppa/stable
    sudo apt install -y neovim

    # Python modules prerequisites
    sudo apt install python-dev python-pip python3-dev python3-pip

    # use Neovim for all editor alternatives
    sudo update-alternatives --install /usr/bin/vi vi /usr/bin/nvim 60
    sudo update-alternatives --config vi
    sudo update-alternatives --install /usr/bin/vim vim /usr/bin/nvim 60
    sudo update-alternatives --config vim
    sudo update-alternatives --install /usr/bin/editor editor /usr/bin/nvim 60
    sudo update-alternatives --config editor

    mkdir --parents --verbose $HOME/.config/nvim/
    ln --symbolic --force --verbose $HOME/dotfiles/.config/nvim/init.vim $HOME/.config/nvim/

    # setup a Python virtual environment for Neovim
    # https://github.com/deoplete-plugins/deoplete-jedi/wiki/Setting-up-Python-for-Neovim#using-virtual-environments
    pyenv virtualenv neovim
    pyenv activate neovim
    pip install neovim
    pyenv deactivate

    # setup vim-plug
    # https://github.com/junegunn/vim-plug
    sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

    # install packages with vim-plug
    vim +PlugInstall +qa
}


setup_nodejs() {
    # https://nodejs.org/

    # https://github.com/nvm-sh/nvm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash

    # TODO
    # verify path is correct
    # https://superuser.com/questions/365847/where-should-the-xdg-config-home-variable-be-defined/425712#425712
    export NVM_DIR="$HOME/.nvm"
    [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

    nvm install --lts
}


install_z() {
    # z
    # https://github.com/rupa/z
    # NOTE
    # check my own fork that supports smart case sensitivity by merging ericbn's
    # pull request https://github.com/rupa/z/pull/221
    # https://github.com/williamstark01/z
    mkdir --parents --verbose $HOME/data/programs

    Z_ROOT_DIRECTORY="$HOME/data/programs/z"
    [[ -d "$Z_ROOT_DIRECTORY" ]] && backup_datetime "$Z_ROOT_DIRECTORY"
    git clone https://github.com/rupa/z.git "$Z_ROOT_DIRECTORY"
}


install_desktop_packages() {
    # CopyQ
    # https://github.com/hluk/CopyQ

    # Evince
    # https://wiki.gnome.org/Apps/Evince

    # filelight
    # https://apps.kde.org/filelight/

    # Gimp
    # https://www.gimp.org/
    # https://launchpad.net/~ubuntuhandbook1/+archive/ubuntu/gimp
    #sudo add-apt-repository ppa:ubuntuhandbook1/gimp

    # GNOME Disks
    # https://wiki.gnome.org/Apps/Disks
    # https://gitlab.gnome.org/GNOME/gnome-disk-utility

    # GoldenDict
    # http://goldendict.org/

    # GParted
    # https://gparted.org/

    # Grub Customizer
    # https://launchpad.net/grub-customizer

    # KDiff3
    # https://apps.kde.org/kdiff3/

    # KeePassXC
    # https://keepassxc.org/
    # https://github.com/keepassxreboot/keepassxc

    # qBittorrent
    # https://www.qbittorrent.org/
    # https://github.com/qbittorrent/qBittorrent

    # Thunderbird
    # https://www.thunderbird.net/

    DESKTOP_PACKAGES=(
        copyq
        evince
        filelight
        gimp
        gnome-disk-utility
        goldendict
        gparted
        grub-customizer
        kdiff3
        keepassxc
        qbittorrent
        thunderbird
    )

    sudo apt install -y $DESKTOP_PACKAGES
}


install_google_chrome() {
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
    sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
    sudo apt install -y google-chrome-stable
}


setup_ufw_firewall() {
    echo "Setting up the ufw firewall..."

    # deny all incoming connections, allow outgoing connections
    sudo ufw default deny incoming
    sudo ufw default allow outgoing

    # allow incoming SSH connections
    sudo ufw allow ssh

    # allow incoming HTTP and HTTPS connections
    sudo ufw allow http
    sudo ufw allow https

    # turn on the firewall
    sudo ufw enable

    # check the status of the firewall
    sudo ufw status
}


main() {
    cd $HOME

    # global variables
    SCRIPT_USER=$USER
    echo "logged in as user $SCRIPT_USER"


    YES_NO_ANSWER=$(yes_no_question "Do you have superuser rights on this system?")
    if [[ $YES_NO_ANSWER = "y" ]]; then
        SUPERUSER_RIGHTS=1
    else
        SUPERUSER_RIGHTS=0
        echo "Skipping commands that require superuser rights."
    fi

    if [[ "$SUPERUSER_RIGHTS" == "1" ]]; then
        YES_NO_ANSWER=$(yes_no_question "Update and upgrade the system?")
        if [[ $YES_NO_ANSWER = "y" ]]; then
            sudo apt update && sudo apt -y upgrade && sudo apt dist-upgrade
        fi
    fi


    # configuration
    ################################################################################

    # create $HOME directories
    mkdir --parents --verbose bin
    mkdir --parents --verbose ".config"

    backup_datetime dotfiles
    git clone https://github.com/williamstark01/dotfiles.git


    DOTFILES=(
        .bash_profile
        .bashrc
        .inputrc
        .profile
        .tmux.conf
    )

    for DOTFILE in "${DOTFILES[@]}"; do
        backup_datetime "$DOTFILE"
    done

    for DOTFILE in "${DOTFILES[@]}"; do
        ln --symbolic --force --verbose $HOME/dotfiles/"$DOTFILE" $HOME/
    done


    backup_datetime .bashrc_local
    cp --interactive --verbose $HOME/dotfiles/.bashrc_local $HOME/

    backup_datetime .gitconfig
    cp --interactive --verbose $HOME/dotfiles/.gitconfig $HOME/

    # Konsole Tomorrow theme
    # https://github.com/dram/konsole-tomorrow-theme
    if [[ -d "$HOME/.local/share/konsole/" ]]; then
        ln --symbolic --force --verbose $HOME/dotfiles/.local/share/konsole/Tomorrow.colorscheme $HOME/.local/share/konsole/
    fi
    ################################################################################


    if [[ "$SUPERUSER_RIGHTS" == "1" ]]; then
        sudo apt install -y $STANDARD_PACKAGES

        # setup unattended security upgrades
        sudo apt install unattended-upgrades
        sudo dpkg-reconfigure unattended-upgrades

        create_data_directory

        setup_python
        setup_python_programs

        setup_neovim

        setup_nodejs

        install_z

        YES_NO_ANSWER=$(yes_no_question "Is this a desktop system?")
        if [[ $YES_NO_ANSWER = "y" ]]; then
            install_desktop_packages

            install_google_chrome
        fi

        YES_NO_ANSWER=$(yes_no_question "Is this a server system?")
        if [[ $YES_NO_ANSWER = "y" ]]; then
            # Fail2ban
            # https://github.com/fail2ban/fail2ban

            # ufw
            # https://launchpad.net/ufw

            sudo apt install -y fail2ban ufw

            setup_ufw_firewall
        fi
    fi


    # install the linux-headers and build-essential packages
    if [[ "$SUPERUSER_RIGHTS" == "1" ]]; then
        YES_NO_ANSWER=$(yes_no_question "Install linux-headers and build-essential packages?")
        if [[ $YES_NO_ANSWER = "y" ]]; then
            sudo apt install -y linux-headers-generic build-essential
        fi
    fi
}


main


echo ""
echo "System setup successful!"
