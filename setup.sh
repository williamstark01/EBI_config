#!/usr/bin/env bash

# William Stark (william@ebi.ac.uk)


# Set up configuration and applications on the Codon cluster.


# Exit immediately if a pipeline (which may consist of a single  simple  command),
# a list, or a compound command, exits with a non-zero status.
set -e


TEAM_NAME=genebuild

NFS_ROOT="/nfs/production/flicek/ensembl/$TEAM_NAME/$USER"
HPS_ROOT="/hps/nobackup/flicek/ensembl/$TEAM_NAME/$USER"
SOFTWARE_ROOT="/hps/software/users/ensembl/$TEAM_NAME/$USER"


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


setup_tmux() {
    # install third-party tmux AppImage
    # https://github.com/nelsonenzo/tmux-appimage

    TMUX_DIR="$SOFTWARE_ROOT/programs/tmux"
    mkdir --parents --verbose "$TMUX_DIR"
    cd "$TMUX_DIR"
    curl -LO https://github.com/nelsonenzo/tmux-appimage/releases/download/3.2a/tmux.appimage
    chmod u+x "$TMUX_DIR/tmux.appimage"

    #ln --symbolic --force --verbose "$TMUX_DIR/tmux.appimage" "$HOME/bin/tmux"

    # NOTE
    # original AppImage doesn't run on Codon compute nodes, extract and symlink to AppRun script
    "$TMUX_DIR/tmux.appimage" --appimage-extract
    ln --symbolic --force --verbose "$TMUX_DIR/squashfs-root/AppRun" "$HOME/bin/tmux"

    cd "$HOME"

    # tmux bash completion
    # https://github.com/imomaliev/tmux-bash-completion
    git clone https://github.com/imomaliev/tmux-bash-completion.git "$SOFTWARE_ROOT/programs/tmux-bash-completion"
}


setup_python() {
    # https://www.python.org/

    # install pyenv
    # Python version manager
    # https://github.com/pyenv/pyenv
    if [[ -n "$PYENV_ROOT" ]]; then
        backup_datetime "$PYENV_ROOT"
    else
        PYENV_ROOT="$NFS_ROOT/.pyenv"
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
    #ENSEMBL_SOFTWARE_HOME=/hps/software/users/ensembl/ensw/C8-MAR21-sandybridge

    #HOMEBREW_ENSEMBL_MOONSHINE_ARCHIVE=/hps/software/users/ensembl/ensw/ENSEMBL_MOONSHINE_ARCHIVE
    #ENSEMBL_MOONSHINE_ARCHIVE=/hps/software/users/ensembl/ensw/ENSEMBL_MOONSHINE_ARCHIVE

    LINUXBREW_HOME=/hps/software/users/ensembl/ensw/C8-MAR21-sandybridge/linuxbrew
    PATH="$LINUXBREW_HOME/bin:$LINUXBREW_HOME/sbin:$PATH"
    MANPATH="$LINUXBREW_HOME/share/man:$MANPATH"
    INFOPATH="$LINUXBREW_HOME/share/info:$INFOPATH"
    ################################################################################

    # install latest bugfix version of preferred Python minor version
    PREFERRED_PYTHON_MINOR_VERSION="3.9"
    LATEST_PREFERRED_PYTHON_VERSION=$(pyenv latest --print "$PREFERRED_PYTHON_MINOR_VERSION")
    CC=gcc-10 CPPFLAGS="-I$LINUXBREW_HOME/include -I/usr/include" LDFLAGS="-L$LINUXBREW_HOME/lib -L/usr/lib64" pyenv install "$LATEST_PREFERRED_PYTHON_VERSION"

    # set global Python to latest
    pyenv global "$LATEST_PREFERRED_PYTHON_VERSION"

    # upgrade global Python pip
    pip install --upgrade pip

    # link $HOME/.pylintrc and .config/flake8
    #ln --symbolic --force --verbose $HOME/dotfiles/.pylintrc $HOME/
    #ln --symbolic --force --verbose $HOME/dotfiles/.config/flake8 $HOME/.config/

    # install pipx
    # Install and Run Python Applications in Isolated Environments
    # https://github.com/pypa/pipx
    python3 -m pip install --user pipx
    python3 -m pipx ensurepath

    PIPX_BIN_DIR="$HOME/.local/bin"
    export PATH="$PIPX_BIN_DIR:$PATH"

    # Poetry
    # Python dependency manager
    # https://github.com/python-poetry/poetry
    pipx install poetry

    # Black
    # Python code formatter
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


setup_rust() {
    # https://www.rust-lang.org/

    export RUSTUP_HOME="$SOFTWARE_ROOT/.rustup"
    export CARGO_HOME="$SOFTWARE_ROOT/.cargo"
    export PATH="$CARGO_HOME/bin:$PATH"

    # install Rust
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

    # exa
    # modern ls replacement
    # https://github.com/ogham/exa
    cargo install exa

    # fd
    # find replacement (search for files)
    # https://github.com/sharkdp/fd
    cargo install fd-find

    # delta
    # a syntax-highlighting pager for git and diff output
    # https://github.com/dandavison/delta
    cargo install git-delta

    # ripgrep
    # recursively search file contents for a regex pattern
    # https://github.com/BurntSushi/ripgrep
    cargo install ripgrep
}


setup_nodejs() {
    # https://nodejs.org/

    # https://github.com/nvm-sh/nvm
    export NVM_DIR="$SOFTWARE_ROOT/.nvm"
    mkdir --parents --verbose "$NVM_DIR"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash

    [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

    # install latest LTS version
    nvm install --lts
}


setup_more() {
    # direnv
    # automatically load and unload environment variables when changing directory
    # https://github.com/direnv/direnv
    export bin_path="$HOME/bin"; curl -sfL https://direnv.net/install.sh | bash
}


main() {
    # verify running on the Codon cluster
    if [[ $LSF_ENVDIR != "/ebi/lsf/codon/conf" ]]; then
        echo "This setup script is designed for the Codon cluster, exiting."
        kill -INT $$
    fi

    cd "$HOME"

    # create $HOME directories
    mkdir --parents --verbose "$HOME/data"
    mkdir --parents --verbose "$HOME/bin"
    mkdir --parents --verbose "$HOME/.config"

    # create nfs, hps, and software user directories
    mkdir --parents --verbose "$NFS_ROOT"
    bsub -Is mkdir --parents --verbose "$HPS_ROOT"
    mkdir --parents --verbose "$SOFTWARE_ROOT"
    mkdir --parents --verbose "$SOFTWARE_ROOT/programs"


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
        ln --symbolic --force --verbose "$HOME/dotfiles/$DOTFILE" "$HOME/"
    done

    backup_datetime .bashrc_local
    cp --interactive --verbose "$HOME/dotfiles/.bashrc_local" "$HOME/"
    ############################################################################


    # disable less `s` key log feature
    # (specify custom key bindings for less, described in `$HOME/.lesskey`)
    # man lesskey
    ln --symbolic --force --verbose "$HOME/dotfiles/.lesskey" "$HOME/"
    lesskey


    # EBI_config setup
    # https://github.com/williamstark01/EBI_config
    ############################################################################
    backup_datetime EBI_config

    git clone https://github.com/williamstark01/EBI_config.git

    ln --symbolic --force --verbose "$HOME/EBI_config/.bashrc_codon" "$HOME/"
    ############################################################################

    install_z

    setup_tmux

    setup_python

    setup_neovim

    setup_rust

    setup_nodejs

    setup_more
}


main


echo ""
echo "Setup successful!"
