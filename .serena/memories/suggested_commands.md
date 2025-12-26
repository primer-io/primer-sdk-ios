# Suggested Commands for Development

## Initial Setup

### Install Dependencies
```bash
# Install Ruby dependencies (Fastlane, CocoaPods)
bundle install

# Install SwiftFormat via Homebrew
brew install swiftformat

# Set up git pre-commit hook for automatic formatting
make hook
```

### Install Pod Dependencies (for Debug App)
```bash
cd "Debug App"
bundle exec pod install
cd ..
```

## Code Formatting

### Format Swift Code
```bash
# Format a specific file
swiftformat <file.swift> --config BuildTools/.swiftformat

# Format entire project
swiftformat . --config BuildTools/.swiftformat

# Format with stdin (used by pre-commit hook)
swiftformat --config BuildTools/.swiftformat stdin --stdinpath 'path/to/file.swift'
```

### Check Formatting (without applying)
```bash
swiftformat . --config BuildTools/.swiftformat --lint
```

## Testing

### Run SDK Tests (Swift Package Manager)
```bash
# Run tests with default simulator (iPhone 16, iOS 18.4)
bundle exec fastlane test_sdk

# Run tests with specific iOS version
bundle exec fastlane test_sdk sim_version:18.4
```

### Run SDK Tests (CocoaPods)
```bash
bundle exec fastlane tests
```

### Run Debug App Tests
```bash
# Run with default simulator
bundle exec fastlane test_debug_app

# Run with specific iOS version
bundle exec fastlane test_debug_app sim_version:18.4
```

### Run UI Tests
```bash
bundle exec fastlane ui_tests
```

## Building

### Build Debug App
```bash
# Via Xcode - open workspace
open PrimerSDK.xcworkspace

# Via Fastlane (for QA release)
bundle exec fastlane qa_release
```

### Clean Build
```bash
# Clean SPM build folder
rm -rf .build

# Clean CocoaPods
cd "Debug App"
bundle exec pod deintegrate
bundle exec pod install
cd ..
```

## Continuous Integration

### Run Danger Checks
```bash
# Run PR checks (requires GITHUB_TOKEN)
bundle exec fastlane danger_check
```

## Git Operations

### Commit Changes
The pre-commit hook (installed via `make hook`) automatically formats staged Swift files before committing:
```bash
git add .
git commit -m "Your commit message"
# Hook automatically runs: ./BuildTools/git-format-staged.sh
```

### Skip Pre-commit Hook (not recommended)
```bash
git commit --no-verify -m "Your message"
```

## Package Management

### Update Swift Package Dependencies
```bash
swift package update
```

### Resolve Swift Package Dependencies
```bash
swift package resolve
```

### Update CocoaPods
```bash
cd "Debug App"
bundle exec pod update
cd ..
```

## Useful Darwin System Commands

### Find Files
```bash
# Find Swift files
find . -name "*.swift" -type f

# Using mdfind (macOS Spotlight)
mdfind -name "filename.swift"
```

### Search in Files
```bash
# Search for text in Swift files
grep -r "search_term" --include="*.swift" .

# Case-insensitive search
grep -ri "search_term" --include="*.swift" .
```

### List Directory Structure
```bash
# List directories only
ls -d */

# Tree structure (if installed: brew install tree)
tree -L 2 -d
```

### Check iOS Simulators
```bash
# List available simulators
xcrun simctl list devices available

# Boot a simulator
xcrun simctl boot "iPhone 16"
```
