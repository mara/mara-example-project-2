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
  postgresql

RUN mkdir /mara

# this is changing the current working directory to the mara app directory
WORKDIR /mara

# exposing the flask application default port
EXPOSE 5000

CMD ["bash"]
