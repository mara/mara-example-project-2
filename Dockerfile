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

# this is changing the current working directory to the mara app directory
WORKDIR /mara

COPY ./app/docker_local_setup.py /mara/app/local_setup.py

#COPY ./app/ ./

# exposing the flask application port
EXPOSE 5000

COPY init.sh /mara/
RUN ["chmod", "+x", "/mara/init.sh"]

COPY Makefile /mara/
RUN ["chmod", "+x", "/mara/Makefile"]

CMD ["bash", "/mara/init.sh"]
#CMD ["bash"]
