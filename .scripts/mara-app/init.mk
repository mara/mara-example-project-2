# Makefile boilerplate

# custom shell for coloring + timing
SHELL=.scripts/mara-app/makeshell $(or $@,-)

# disable command echoing, will be done by makeshell
.SILENT:

# copy scripts from mara-app package to project code
.copy-mara-app-scripts:
	rsync --archive --recursive --itemize-changes  --delete packages/mara-app/.scripts/ .scripts/mara-app/



