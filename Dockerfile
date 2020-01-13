# this tells docker to build this image on top of python version 3.6.*
FROM python:3.7

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

# terminal colors with xterm
ENV TERM xterm
# set the zsh theme
ENV ZSH_THEME agnoster

# zsh installation
RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true

# this is changing the current working directory to the mara app directory
WORKDIR /mara

# exposing the flask application port
EXPOSE 5000

CMD ["zsh"]
