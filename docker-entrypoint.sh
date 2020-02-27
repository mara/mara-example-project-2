#!/bin/sh
# mara-app image entrypoint script

# Create the Python3 virtual environment and installs all required dependencies
# for running and exposing the Flask application at host:5000

if [[ ! -d ".venv" ]]; then
  make
fi

make run-flask
