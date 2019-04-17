#!/bin/bash

#rm -rf .venv

# Create the virtual env for the first time
if [ ! -d ".venv" ]; then
  make
fi
source .venv/bin/activate
flask run --with-threads --host 0.0.0.0 --reload --eager-loading
