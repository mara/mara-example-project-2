# this tells docker to build this image on top of python version 3.6.*
FROM python:3.6

# Install environment dependencies
RUN apt-get update && apt-get install -y \
  git \
  dialog \
  coreutils \
  graphviz \
#  python-3 \
  python3-dev \
  python3-venv

# create any additional mara app folder
RUN mkdir /mara-example-project

# this is changing the current working directory to the mara app directory
# this is required since it is that folder where we find the requirements.txt
WORKDIR /mara-example-project

# here we are copying all contents of the current folder where the dockerfile resides to the mara app dir
#COPY . /mara-example-project

#RUN chmod +x init_mara.sh
#RUN ./init_mara.sh

# exposing the flask application default port
EXPOSE 5000

CMD ["bash"]

