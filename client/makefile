.PHONY: build check-elm clean clean-elm deps distclean install
.SECONDEXPANSION:
.DEFAULT_GOAL := help

BUILDDIR ?= '_build'
DESTDIR ?= '../server/priv/static'


build: $(addprefix $(BUILDDIR)/, elm.js index.html)
build: ## Builds application into $(BUILDDIR)
	cp -r assets $(BUILDDIR)/
	cp -r node_modules/uswds/dist/* $(BUILDDIR)/assets/


install: build
install: ## Puts build files into $(DESTDIR)
	mkdir -p $(DESTDIR)
	cp -r $(BUILDDIR)/* $(DESTDIR)


deps: ## Installs project dependencies
	npm install
	elm package install --yes


clean: clean-elm
clean: ## Deletes build artifacts
	rm -r $(BUILDDIR)


clean-elm: ## Deletes Elm build artifacts
	rm -r elm-stuff/build-artifacts


distclean: clean
distclean: ## Deletes all non-source code stuff
	rm -r elm-stuff node_modules


check-elm: clean-elm $(BUILDDIR)/elm.js
check-elm: ## Rebuilds application for warnings


ELM_FILES := $(shell find src/ -type f -name '*.elm')
$(BUILDDIR)/elm.js: $(ELM_FILES) | $$(@D)/.
	elm make --warn src/Main.elm --output $@


$(BUILDDIR)/index.html: index.html | $$(@D)/.
	cp index.html $@


# Trick to make it easy to ensure a target's parent directories are created
# before we try to use them, just add a `| $$(@D)/.` to the dependencies of a
# target to ensure the directories in it's path are created
%/.:
	mkdir -p $@


# Self-documenting make file
# (http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html)
help: ## Displays this help screen
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "BUILDDIR: $(BUILDDIR)"
	@echo "DESTDIR: $(DESTDIR)"
