.PHONY: hook check-deps

check-deps:
	@echo "Checking dependencies..."
	@if ! command -v brew >/dev/null 2>&1; then \
		echo "Error: Homebrew is not installed."; \
		echo "Please install Homebrew first by running:"; \
		echo "/bin/bash -c \"$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""; \
		exit 1; \
	fi
	@echo "✓ Homebrew is installed"
	@if ! command -v swiftformat >/dev/null 2>&1; then \
		echo "SwiftFormat not found. Installing via Homebrew..."; \
		brew install swiftformat; \
		if [ $$? -eq 0 ]; then \
			echo "✓ SwiftFormat installed successfully"; \
		else \
			echo "Error: Failed to install SwiftFormat"; \
			exit 1; \
		fi; \
	else \
		echo "✓ SwiftFormat is already installed"; \
	fi

hook: check-deps
	@echo "Setting up pre-commit hook..."
	@if [ ! -d .git/hooks ]; then \
		echo "Git hooks directory does not exist, creating..."; \
		mkdir -p .git/hooks; \
	fi
	@if [ ! -f .git/hooks/pre-commit ]; then \
		echo "#!/bin/bash" > .git/hooks/pre-commit; \
		echo "./BuildTools/git-format-staged.sh --formatter \"swiftformat --config BuildTools/.swiftformat stdin --stdinpath '{}'\" \"*.swift\"" >> .git/hooks/pre-commit; \
		chmod +x .git/hooks/pre-commit; \
		echo "Pre-commit hook installed successfully."; \
	else \
		echo "Pre-commit hook already exists. Installation skipped."; \
	fi
