hook:
	@echo "Setting up pre-commit hook..."

	@# Check and install swiftformat if needed
	@command -v swiftformat >/dev/null 2>&1 || { \
		echo "swiftformat not found. Installing with Homebrew..."; \
		brew install swiftformat || { echo "Failed to install swiftformat"; exit 1; }; \
	}

	@# Ensure the Git hooks directory exists
	@if [ ! -d .git/hooks ]; then \
		echo "Git hooks directory does not exist, creating..."; \
		mkdir -p .git/hooks; \
	fi

	@# Install the pre-commit hook if it doesn't already exist
	@if [ ! -f .git/hooks/pre-commit ]; then \
		echo "#!/bin/bash" > .git/hooks/pre-commit; \
		echo "BuildTools/git-format-staged.sh --formatter \"swiftformat --config BuildTools/.swiftformat stdin --stdinpath '{}'\" \"*.swift\"" >> .git/hooks/pre-commit; \
		chmod +x .git/hooks/pre-commit; \
		echo "Pre-commit hook installed successfully."; \
	else \
		echo "Pre-commit hook already exists. Installation skipped."; \
	fi
