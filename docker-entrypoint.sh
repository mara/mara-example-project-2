#!/bin/sh

# mara-app image entrypoint script
# Create required dependencies, if not there, and run the flask application

# Copy local_setup.py if not there
if [[ ! -f "/mara/app/local_setup.py" ]]; then
    echo "local_setup.py was automatically created from the local_setup.py.example"
    cp /mara/app/local_setup.py.example /mara/app/local_setup.py
fi

if [[ ! -d ".venv" ]]; then
  make
fi

make run-flask
