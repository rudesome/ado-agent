all: agent

agent: ## build azure devops agent
	@echo "build docker nix in docker with nix"
	nix build .#agent --json --no-link --print-build-logs | jq -r \".[0].outputs.out\"

develop: ## nix develop shell
	nix develop

.PHONY: help
help:  ## this help messages
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}'
