---
name: fix-issue
description: Fix a Jira issue end-to-end
disable-model-invocation: true
argument-hint: "[CHKT-XXXX]"
---

Fix the issue: $ARGUMENTS

## Workflow

1. **Read the issue**: Use Atlassian MCP tool `getJiraIssue` to fetch the Jira ticket details
2. **Understand the problem**: Analyze description, reproduction steps, expected vs actual behavior
3. **Create a branch**: `git checkout -b fix/$TICKET-short-description` (e.g. `fix/CHKT-1234-card-validation`)
4. **Search the codebase**: Find relevant files, understand current behavior, identify root cause
5. **Implement the fix**: Make the minimal necessary changes to resolve the issue
6. **Write tests**: Add or update tests to cover the fix — follow project test patterns (see `.claude/rules/testing.md`)
7. **Verify code quality** (hooks auto-run SwiftFormat + SwiftLint --fix on every edit, but verify no warnings remain):
   ```bash
   swiftlint lint --config "Debug App/.swiftlint.yml"
   ```
8. **Run tests** (only the touched/new test classes):
   ```bash
   xcodebuild -workspace PrimerSDK.xcworkspace \
     -scheme "PrimerSDKTests" \
     -destination "platform=iOS Simulator,name=iPhone 16,OS=18.6" \
     -testPlan "UnitTestsTestPlan" \
     -only-testing:"Tests/{TestClassName}" \
     test
   ```
9. **Verify UI changes** (if the fix involves UI):
   - Build the Debug App
   - Use ios-simulator MCP tools to boot simulator, launch the Debug App (bundle ID: `com.primerapi.PrimerSDKExample`), navigate to the affected screen, and take a screenshot
   - Verify the fix visually
10. **Commit**: Use conventional commit format (`fix: Description of fix`)
