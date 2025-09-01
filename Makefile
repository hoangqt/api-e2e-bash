.PHONY: lint format test help

test: ## run all tests
	tests/testgithub.sh

lint: ## lint scripts
	shellcheck tests/*.sh

format: ## format shell scripts
	shfmt -w tests/*.sh

# https://www.client9.com/self-documenting-makefiles/
help:
	@awk -F ':|##' '/^[^\t].+?:.*?##/ {\
		printf "\033[36m%-30s\033[0m %s\n", $$1, $$NF \
		}' $(MAKEFILE_LIST)

.DEFAULT_GOAL=help
