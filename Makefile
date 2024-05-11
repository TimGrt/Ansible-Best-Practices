.PHONY: all help deps clean

.DEFAULT_GOAL:=help
SHELL:=/bin/bash

# Variables
COLOUR_RED:=$(shell tput setaf 1)
COLOUR_GREEN:=$(shell tput setaf 2)
COLOUR_YELLOW:=$(shell tput setaf 3)
COLOUR_BLUE:=$(shell tput setaf 4)
COLOUR_END:=$(shell tput sgr0)

VENV_NAME?=ve-mkdocs-dev
PYTHON=${VENV_NAME}/bin/python

help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "This \033[34mMakefile\033[0m sets up a development environment for the \033[34mAnsible Best Practice Guide\033[0m.\n\nUsage:\n  make \033[34m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[34m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

all: venv hooks serve  ## Runs all targets

venv: $(VENV_NAME)/bin/activate  ## Creates Python virtual environment
	$(info $(COLOUR_BLUE)## Python virtual environment is ready.$(COLOUR_END))

$(VENV_NAME)/bin/activate: requirements.txt
	$(info $(COLOUR_BLUE)## Creating Python virtual environment and installing dependencies...$(COLOUR_END))
	@test -d $(VENV_NAME) || (virtualenv -p python3 $(VENV_NAME) && echo -e "$(COLOUR_GREEN)##Python VE created.$(COLOUR_END)")
	@${PYTHON} -m pip install -r requirements.txt && echo -e "$(COLOUR_GREEN)## Python requirements installed.$(COLOUR_END)"
	@${PYTHON} -m pip install pre-commit && echo -e "$(COLOUR_GREEN)## pre-commit package installed.$(COLOUR_END)"
	@touch $(VENV_NAME)/bin/activate

hooks: pre-commit-install ## Installs pre-commit hooks
	$(info $(COLOUR_BLUE)## pre-commit is ready.$(COLOUR_END))

pre-commit-install:
ifeq ("$(wildcard .git/hooks/pre-commit)","")
	@pre-commit install && echo -e "$(COLOUR_GREEN)## Hooks installed.$(COLOUR_END)"
endif

serve:  ## Output instructions for running MkDocs development server
ifneq ($(shell pwd)/$(PYTHON), $(shell which python))
	@echo -e "$(COLOUR_YELLOW)## Python VE is not activated!$(COLOUR_END)"
	@echo -e "$(COLOUR_GREEN)## Run$(COLOUR_END) source $(VENV_NAME)/bin/activate $(COLOUR_GREEN)first.$(COLOUR_END)"
endif
	@echo -e "$(COLOUR_GREEN)## Run$(COLOUR_END) mkdocs serve -o$(COLOUR_GREEN) for a live preview.$(COLOUR_END)"

clean: ## Cleanup the project folders
	$(info $(COLOUR_BLUE)## Cleaning up things...$(COLOUR_END))
ifeq ($(shell pwd)/$(PYTHON), $(shell which python))
	$(error $(COLOUR_RED)## Cleanup aborted!$(COLOUR_YELLOW) Python VE is still activated! Leave the VE by running$(COLOUR_END) deactivate $(COLOUR_YELLOW)first$(COLOUR_END))
endif
	@rm -rf $(VENV_NAME) &&	echo -e "$(COLOUR_GREEN)## Python VE removed.$(COLOUR_END)"
	@rm -rf .git/hooks/pre-commit && echo -e "$(COLOUR_GREEN)## pre-commit hooks removed.$(COLOUR_END)"
	@rm -rf ~/.cache/pre-commit && echo -e "$(COLOUR_GREEN)## pre-commit cache removed.$(COLOUR_END)"
