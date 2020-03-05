"""Initializes the flask application"""

import pathlib
import sys
from shutil import copy

# configure application and packages
import app.data_integration
import app.bigquery_downloader
import app.data_sets
import app.ui

# apply environment specific settings (not in git repo)
if not pathlib.Path(__file__).parent.joinpath('local_setup.py').exists():
    sys.stderr.write('IMPORTANT: Local configuration was adapted automatically from app/local_setup.py.example '
                     'to app/local_setup.py. Please check configuration and adapt any changes accordingly.\n')
    copy('app/local_setup.py.example', 'app/local_setup.py')

import app.local_setup
