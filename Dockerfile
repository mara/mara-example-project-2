FROM python:3.7

# Default working directory
WORKDIR /mara

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
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
  sudo \
  && locale-gen en_US.UTF-8

COPY docker-entrypoint.sh /mara/
RUN ["chmod", "+x", "/mara/docker-entrypoint.sh"]

ARG MARA_USER=1000
RUN useradd -ms /bin/bash ${MARA_USER} && echo "${MARA_USER}:${MARA_USER}" | chpasswd && adduser ${MARA_USER} sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Install and configure OhMyZSH
ENV TERM xterm
ENV ZSH_THEME robbyrussell
RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true \
 && git clone https://github.com/sindresorhus/pure $HOME/.oh-my-zsh/custom/pure \
 && ln -s $HOME/.oh-my-zsh/custom/pure/pure.zsh-theme $HOME/.oh-my-zsh/custom/ \
 && ln -s $HOME/.oh-my-zsh/custom/pure/async.zsh $HOME/.oh-my-zsh/custom/ \
 && sed -i -e 's/robbyrussell/${ZSH_THEME}/g' $HOME/.zshrc

CMD ["zsh"]