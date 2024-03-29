﻿.PHONY: \
	check-master-repo-clean \
	check-projects-for-merge \
	check-projects-for-release \
	build-debug \
	build-night \
	build-release \
	rebuild-debug \
	rebuild-night \
	rebuild-release \
	to-master \
	to-develop \
	to-develop-all \
	git-status \
	latest-git-tags \
	tag-versions \
	remove-latest-tags \
	push-to-develop \
	push-to-master \
	push-master-to-develop \
	merge-develop \
	reset-master-to-origin \
	new-changelog-entries \
	create-changelogs \
	reformat-changelogs \
	build-packages \
	check-packages \
	publish-releases-github \
	publish-releases-spacedock \
	merge-build-and-tag-releases \
	package-releases \
	release \
	rollback-merge-and-tags

ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

SKIP_REPOS = "UI/HSV-Color-Picker-Unity"|PyKSPutils

GIT_SUB_DF = git submodule foreach 'git submodule foreach '"'"' COMMAND '"'"' && COMMAND '

CASE_CMD = \
	case $$name in \
	$(SKIP_REPOS)) \
		echo "Skipping $${name}.\n" ;; \
	*) \
		echo "Working on $${name}:" && \
		COMMAND && echo "Done in $${name}.\n" ;; \
	esac

GIT_SUB := $(GIT_SUB_DF:COMMAND=$(CASE_CMD))

# project checks

KSP_PLUGIN_CMD = $(ROOT_DIR)/venv/bin/ksp_plugin
PIP = $(ROOT_DIR)/venv/bin/pip
PYTHON = $(ROOT_DIR)/venv/bin/python

venv: requirements.txt PyKSPutils/setup.py PyKSPutils/requirements.txt PyKSPutils/requirements-dev.txt
	[ -d "$(ROOT_DIR)/venv" ] || python -m venv $(ROOT_DIR)/venv
	$(PIP) install -U pip setuptools
	$(PIP) install -r requirements.txt
	$(PIP) install -r PyKSPutils/requirements-dev.txt
	touch $(ROOT_DIR)/venv

check-master-repo-clean:
	git diff
	git diff --quiet

check-projects-for-merge: venv check-master-repo-clean
	$(GIT_SUB:COMMAND=$(KSP_PLUGIN_CMD) check for-merge)

check-projects-for-release: venv
	$(GIT_SUB:COMMAND=$(KSP_PLUGIN_CMD) check for-release)

show-info: venv
	$(GIT_SUB:COMMAND=$(KSP_PLUGIN_CMD) info)

# msbuild tasks

BUILD = msbuild -m ./AT_KSP_Plugins.sln

build-debug:
	$(BUILD) /property:Configuration=Debug

build-night:
	$(BUILD) /property:Configuration=Nightbuild

build-release:
	$(BUILD) /property:Configuration=Release

clean:
	$(BUILD) -t:Clean

rebuild-debug: clean build-debug

rebuild-night: clean build-night

rebuild-release: clean build-release

# git tasks

to-master:
	$(GIT_SUB:COMMAND=git checkout master)

to-develop:
	$(GIT_SUB:COMMAND=git checkout development)

to-develop-all: to-develop
	git checkout development

git-status:
	$(GIT_SUB:COMMAND=git status -s -b -uno)

git-changelog:
	$(GIT_SUB:COMMAND=git changelog -n -p -x)

latest-git-tags:
	$(GIT_SUB:COMMAND=git describe --abbrev=0 --tags --always)

tag-versions:
	$(GIT_SUB:COMMAND=$(KSP_PLUGIN_CMD) create tag-by-version)

remove-latest-tags:
	$(GIT_SUB:COMMAND=$(KSP_PLUGIN_CMD) remove tag-by-version || :)

PUSH_TO_DEVELOP=git push -f --tags origin development:development
push-to-develop:
	$(GIT_SUB:COMMAND=$(PUSH_TO_DEVELOP))
	$(PUSH_TO_DEVELOP)

PUSH_TO_MASTER=git push --tags origin master:master
push-to-master:
	$(GIT_SUB:COMMAND=$(PUSH_TO_MASTER))

PUSH_MASTER_TO_DEVELOP= \
	git push --tags origin master:development && \
	git fetch origin development:development
push-master-to-develop:
	$(GIT_SUB:COMMAND=$(PUSH_MASTER_TO_DEVELOP))

COMMIT_AND_MERGE = \
	git commit -a -m "Updated submodules"; \
	git merge development --no-ff -m "Merged development branch"

merge-develop: \
	to-develop \
	rebuild-release \
	check-projects-for-merge \
	push-to-develop \
	to-master
	$(GIT_SUB:COMMAND=$(COMMIT_AND_MERGE))

merge-develop-of-master-repo: \
	check-projects-for-release
	git checkout master
	$(COMMIT_AND_MERGE)
	git tag `date +%Y%m%d`
	$(PUSH_TO_MASTER)
	$(PUSH_MASTER_TO_DEVELOP)

reset-master-to-origin: to-develop
	$(GIT_SUB:COMMAND=git fetch -f origin master:master)

# change log
new-changelog-entries: venv
	$(GIT_SUB:COMMAND=$(KSP_PLUGIN_CMD) create changelog-entry)

create-changelogs: venv
	$(GIT_SUB:COMMAND=$(KSP_PLUGIN_CMD) create changelog)

reformat-changelogs: venv
	$(GIT_SUB:COMMAND=$(KSP_PLUGIN_CMD) create changelog --reformat)

# packaging

build-packages: venv
	$(GIT_SUB:COMMAND=$(KSP_PLUGIN_CMD) create archive)

check-packages: venv
	$(GIT_SUB:COMMAND=$(KSP_PLUGIN_CMD) check archive)

publish-releases-github: venv
	$(GIT_SUB:COMMAND=$(KSP_PLUGIN_CMD) github upload || :)

publish-releases-spacedock: venv
	$(GIT_SUB:COMMAND=$(KSP_PLUGIN_CMD) spacedock upload || :)

update-releases-github: venv
	$(GIT_SUB:COMMAND=$(KSP_PLUGIN_CMD) github upload --update || :)

merge-build-and-tag-releases: \
	merge-develop \
	rebuild-release \
	tag-versions

package-releases: \
	check-projects-for-release \
	build-packages \
	check-packages

release: \
	merge-build-and-tag-releases \
	package-releases \
	push-to-master \
	push-master-to-develop \
	merge-develop-of-master-repo \
	publish-releases-github \
	publish-releases-spacedock

rollback-merge-and-tags: \
	reset-master-to-origin \
	remove-latest-tags
