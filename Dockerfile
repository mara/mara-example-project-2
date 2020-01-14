FROM python:3.7

# Arguments
ARG USER=gathineou

RUN useradd -ms /bin/bash ${USER}

# Install environment dependencies
RUN apt-get update && apt-get install -y \
  git \
  dialog \
  coreutils \
  graphviz \
  python3-dev \
  python3-venv \
  rsync \
  nano \
  telnet \
  postgresql \
  zsh \
  # set up locale
  && locale-gen en_US.UTF-8

USER ${USER}

# terminal colors with xterm
ENV TERM xterm
# set the zsh theme
ENV ZSH_THEME refined

# zsh installation
#RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true

# Install and configure OhMyZSH
RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true \
 && git clone https://github.com/sindresorhus/pure $HOME/.oh-my-zsh/custom/pure \
 && ln -s $HOME/.oh-my-zsh/custom/pure/pure.zsh-theme $HOME/.oh-my-zsh/custom/ \
 && ln -s $HOME/.oh-my-zsh/custom/pure/async.zsh $HOME/.oh-my-zsh/custom/ \
 && sed -i -e 's/robbyrussell/${ZSH_THEME}/g' $HOME/.zshrc

# this is changing the current working directory to the mara app directory
WORKDIR /mara

CMD ["zsh"]
