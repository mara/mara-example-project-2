# output coloring & timing
include .scripts/mara-app/init.mk

# virtual env creation, package updates, db migration
include .scripts/mara-app/install.mk

# if you don't want to download the two big
sync-bigquery-csv-data-sets-from-s3:
	.venv/bin/aws s3 sync s3://mara-example-project-data data --delete --no-progress --no-sign-request
