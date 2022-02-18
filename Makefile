.PHONY: \
	check-project-for-merge \
	check-project-for-release \
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
	build-packages \
	check-packages \
	merge-build-and-tag-releases \
	package-releases \
	release \
	rollback-merge-and-tags

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

CHECK_PROJECT = check_project --add-search-path Source

check-project-for-merge:
	git diff
	git diff --quiet
	$(GIT_SUB:COMMAND=$(CHECK_PROJECT) for-merge)

check-project-for-release:
	$(GIT_SUB:COMMAND=$(CHECK_PROJECT) for-release)

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

latest-git-tags:
	$(GIT_SUB:COMMAND=git describe --abbrev=0 --tags --always)

tag-versions:
	$(GIT_SUB:COMMAND=git_tag_by_assembly_info --add-search-path Source create)

remove-latest-tags:
	$(GIT_SUB:COMMAND=git_tag_by_assembly_info --add-search-path Source remove || :)

PUSH_TO_DEVELOP=git push -f --tags origin development:development
push-to-develop:
	$(GIT_SUB:COMMAND=$(PUSH_TO_DEVELOP))

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
	check-project-for-merge \
	push-to-develop \
	to-master
	$(GIT_SUB:COMMAND=$(COMMIT_AND_MERGE))

merge-develop-of-master-repo: \
	check-project-for-release
	git checkout master
	$(COMMIT_AND_MERGE)
	git tag `date +%Y%m%d`
	$(PUSH_TO_MASTER)
	$(PUSH_MASTER_TO_DEVELOP)

reset-master-to-origin: to-develop
	$(GIT_SUB:COMMAND=git fetch -f origin master:master)

# packaging

RELEASES = $(realpath ./AllReleases)
OLD_RELEASES = $(RELEASES)/old

build-packages:
	python3 ./make_releases
	mkdir -p $(RELEASES)
	mv $(RELEASES)/*.zip $(OLD_RELEASES)
	python3 ./gather_releases

check-packages:
	$(GIT_SUB:COMMAND=$(CHECK_PROJECT) check-archive --only-if-exists make-release.sh $(RELEASES))

merge-build-and-tag-releases: \
	merge-develop \
	rebuild-release \
	tag-versions

package-releases: \
	check-project-for-release \
	build-packages \
	check-packages

release: \
	merge-build-and-tag-releases \
	package-releases \
	push-to-master \
	push-master-to-develop \
	merge-develop-of-master-repo

rollback-merge-and-tags: \
	reset-master-to-origin \
	remove-latest-tags
