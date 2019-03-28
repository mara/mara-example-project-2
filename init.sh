#!/bin/bash

rm -rf .venv
make
source .venv/bin/activate
flask run --with-threads --host 0.0.0.0 --reload --eager-loading
