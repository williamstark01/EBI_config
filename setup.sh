#!/usr/bin/env bash

# William Stark (william@ebi.ac.uk)


# Set up configuration and applications on the Codon cluster.


# Exit immediately if a pipeline (which may consist of a single  simple  command),
# a list, or a compound command, exits with a non-zero status.
set -e


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


install_z() {
    # z
    # https://github.com/rupa/z
    # NOTE
    # for smart case sensitivity support check my own fork that merges ericbn's
    # pull request https://github.com/rupa/z/pull/221
    # https://github.com/williamstark01/z

    Z_ROOT_DIRECTORY="$SOFTWARE_ROOT/programs/z"
    [[ -d "$Z_ROOT_DIRECTORY" ]] && backup_datetime "$Z_ROOT_DIRECTORY"
    git clone https://github.com/rupa/z.git "$Z_ROOT_DIRECTORY"
}


setup_python_environment() {
    # https://www.python.org/

    # install pyenv
    # https://github.com/pyenv/pyenv
    if [[ -n "$PYENV_ROOT" ]]; then
        backup_datetime "$PYENV_ROOT"
    else
        PYENV_ROOT="$SOFTWARE_ROOT/.pyenv"
        export PYENV_ROOT
    fi
    # https://github.com/pyenv/pyenv-installer
    curl https://pyenv.run | bash

    # enable pyenv
    export PATH="$PYENV_ROOT/bin:$PATH"
    #eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"

    # install xxenv-latest
    # https://github.com/momo-lab/xxenv-latest
    git clone https://github.com/momo-lab/xxenv-latest.git "$(pyenv root)"/plugins/xxenv-latest

    # load cluster Homebrew
    # /hps/software/users/ensembl/ensw/latest/envs/minimal.sh
    # /hps/software/users/ensembl/ensw/C8-MAR21-sandybridge/envs/linuxbrew.sh
    ################################################################################
    ENSEMBL_SOFTWARE_HOME=/hps/software/users/ensembl/ensw/C8-MAR21-sandybridge

    HOMEBREW_ENSEMBL_MOONSHINE_ARCHIVE=/hps/software/users/ensembl/ensw/ENSEMBL_MOONSHINE_ARCHIVE
    ENSEMBL_MOONSHINE_ARCHIVE=/hps/software/users/ensembl/ensw/ENSEMBL_MOONSHINE_ARCHIVE

    LINUXBREW_HOME=/hps/software/users/ensembl/ensw/C8-MAR21-sandybridge/linuxbrew
    PATH="$LINUXBREW_HOME/bin:$LINUXBREW_HOME/sbin:$PATH"
    MANPATH="$LINUXBREW_HOME/share/man:$MANPATH"
    INFOPATH="$LINUXBREW_HOME/share/info:$INFOPATH"
    ################################################################################

    # install latest Python version
    PYTHON_LATEST_VERSION=$(pyenv latest --print)
    CC=gcc-10 CPPFLAGS="-I$LINUXBREW_HOME/include -I/usr/include" LDFLAGS="-L$LINUXBREW_HOME/lib -L/usr/lib64" pyenv install $PYTHON_LATEST_VERSION
    pyenv global $PYTHON_LATEST_VERSION

    # upgrade global Python pip
    pip install --upgrade pip

    # install Poetry
    # https://github.com/python-poetry/poetry
    curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/install-poetry.py | python -

    # link $HOME/.pylintrc and .config/flake8
    #ln --symbolic --force --verbose $HOME/dotfiles/.pylintrc $HOME/
    #ln --symbolic --force --verbose $HOME/dotfiles/.config/flake8 $HOME/.config/

    # install pipx
    # https://github.com/pypa/pipx
    python3 -m pip install --user pipx
    python3 -m pipx ensurepath

    PIPX_BIN_DIR="$HOME/.local/bin"
    export PATH="$PIPX_BIN_DIR:$PATH"

    # https://github.com/psf/black
    pipx install black
}


setup_neovim() {
    # https://github.com/neovim/neovim

    backup_datetime "$HOME/.config/nvim/init.vim"

    # https://github.com/neovim/neovim/wiki/Installing-Neovim#linux
    # https://github.com/neovim/neovim/releases/latest

    NEOVIM_DIR="$SOFTWARE_ROOT/programs/neovim"
    mkdir --parents --verbose "$NEOVIM_DIR"
    cd "$NEOVIM_DIR"
    curl -LO https://github.com/neovim/neovim/releases/download/stable/nvim.appimage
    chmod u+x "$NEOVIM_DIR/nvim.appimage"
    ./nvim.appimage --appimage-extract
    cd "$HOME"

    ln --symbolic --force --verbose "$NEOVIM_DIR/squashfs-root/AppRun" "$HOME/bin/vim"

    mkdir --parents --verbose "$HOME/.config/nvim"
    ln --symbolic --force --verbose "$HOME/dotfiles/.config/nvim/init.vim" "$HOME/.config/nvim"

    # setup a Python virtual environment for Neovim
    # https://github.com/deoplete-plugins/deoplete-jedi/wiki/Setting-up-Python-for-Neovim#using-virtual-environments
    pyenv virtualenv neovim
    pyenv activate neovim
    pip install --upgrade pip
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
    export NVM_DIR="$SOFTWARE_ROOT/.nvm"
    mkdir --parents --verbose "$NVM_DIR"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash

    [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

    nvm install --lts
}


install_programs() {
    STANDARD_PACKAGES=(
        git
        python-argcomplete
        ripgrep
        tmux
    )

    # TODO
    # install programs used on the cluster
    #sudo apt install -y $STANDARD_PACKAGES

    # TODO
    # setup Rust

    # TODO
    # install with Cargo
    RUST_PACKAGES=(
        delta
        fd
    )
}


main() {
    # verify running on the Codon cluster
    if [[ $LSF_ENVDIR != "/ebi/lsf/codon/conf" ]]; then
        echo "This setup script is designed for the Codon cluster, exiting."
        kill -INT $$
    fi

    cd $HOME

    # create $HOME directories
    mkdir --parents --verbose "$HOME/data"
    mkdir --parents --verbose "$HOME/bin"
    mkdir --parents --verbose "$HOME/.config"
    mkdir --parents --verbose "$HOME/data/programs"

    TEAM_NAME=genebuild

    NFS_ROOT="/nfs/production/flicek/ensembl/$TEAM_NAME/$USER"
    HPS_ROOT="/hps/nobackup/flicek/ensembl/$TEAM_NAME/$USER"
    SOFTWARE_ROOT="/hps/software/users/ensembl/$TEAM_NAME/$USER"

    # create nfs, hps, and software user directories
    mkdir --parents --verbose "$NFS_ROOT"
    bsub -Is mkdir --parents --verbose "$HPS_ROOT"
    mkdir --parents --verbose "$SOFTWARE_ROOT"


    # dotfiles setup
    # https://github.com/williamstark01/dotfiles
    ############################################################################
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
        ln --symbolic --force --verbose $HOME/dotfiles/"$DOTFILE" $HOME/
    done

    backup_datetime .bashrc_local
    cp --interactive --verbose $HOME/dotfiles/.bashrc_local $HOME/
    ############################################################################


    # EBI_config setup
    # https://github.com/williamstark01/EBI_config
    ############################################################################
    backup_datetime EBI_config
    git clone https://github.com/williamstark01/EBI_config.git

    ln --symbolic --force --verbose $HOME/EBI_config/.bashrc_codon $HOME/
    ############################################################################

    install_z

    #install_programs

    YES_NO_ANSWER=$(yes_no_question "Install Python development environment?")
    if [[ $YES_NO_ANSWER = "y" ]]; then
        setup_python_environment
    fi

    YES_NO_ANSWER=$(yes_no_question "Install Neovim (requires Python)?")
    if [[ $YES_NO_ANSWER = "y" ]]; then
        setup_neovim
    fi

    YES_NO_ANSWER=$(yes_no_question "Install Node.js?")
    if [[ $YES_NO_ANSWER = "y" ]]; then
        setup_nodejs
    fi
}


main


echo ""
echo "Config setup successful!"
