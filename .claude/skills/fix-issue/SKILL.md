---
name: fix-issue
description: Fix a GitHub or Jira issue end-to-end
disable-model-invocation: true
argument-hint: "[issue-number-or-url]"
---

Fix the issue: $ARGUMENTS

## Workflow

1. **Read the issue**: Use `gh issue view $ARGUMENTS` for GitHub issues, or fetch the Jira issue details
2. **Understand the problem**: Analyze the issue description, reproduction steps, and expected behavior
3. **Search the codebase**: Find relevant files, understand the current behavior, identify the root cause
4. **Implement the fix**: Make the minimal necessary changes to resolve the issue
5. **Write tests**: Add or update tests to cover the fix — follow project test patterns (see `.claude/rules/testing.md`)
6. **Run code quality tools**:
   - `swiftformat <modified-files> --config BuildTools/.swiftformat`
   - `swiftlint lint --fix --config "Debug App/.swiftlint.yml"`
   - `swiftlint lint --config "Debug App/.swiftlint.yml"` (verify no remaining warnings)
7. **Run tests**: `xcodebuild -workspace PrimerSDK.xcworkspace -scheme "PrimerSDKTests" -destination "platform=iOS Simulator,name=iPhone 16,OS=18.6" test`
8. **Commit**: Use conventional commit format (`fix: Description of fix`)
