---
name: fix-issue
description: Fix a Jira issue end-to-end
disable-model-invocation: true
argument-hint: "[ACC-XXXX]"
---

Fix the issue: $ARGUMENTS

## Workflow

1. **Read the issue**: Use Atlassian MCP tool `getJiraIssue` to fetch the Jira ticket details
2. **Understand the problem**: Analyze description, reproduction steps, expected vs actual behavior
3. **Create a branch**: `git checkout -b fix/$TICKET-short-description` (e.g. `fix/ACC-1234-card-validation`)
4. **Search the codebase**: Find relevant files, understand current behavior, identify root cause
5. **Implement the fix**: Make the minimal necessary changes to resolve the issue
6. **Write tests**: Add or update tests to cover the fix — follow project test patterns (see `.claude/rules/testing.md`)
7. **Verify code quality** on changed Swift files:
   ```bash
   swiftformat <file.swift> --config BuildTools/.swiftformat
   swiftlint lint --fix --config "Debug App/.swiftlint.yml"
   swiftlint lint --config "Debug App/.swiftlint.yml"
   ```
8. **Run tests** for touched/new test classes using the xcodebuild command from CLAUDE.md, with `-only-testing:"Tests/{TestClassName}"` for each class
9. **Verify UI changes** (if applicable): Follow the UI Verification steps in CLAUDE.md
10. **Commit**: Use conventional commit format. Aim for ~50 char subject lines (including prefix) and wrap body text at ~72 chars when possible, but prioritize clarity over strict limits. Example: `fix: Add nil check for card validation`
