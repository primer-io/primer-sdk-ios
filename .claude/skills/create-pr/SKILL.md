---
name: create-pr
description: Create a pull request with proper Primer conventions
disable-model-invocation: true
argument-hint: "[optional-jira-ticket]"
---

Create a pull request for the current branch. Jira ticket: $ARGUMENTS

## Workflow

1. **Run code quality on all modified files**:
   ```bash
   swiftformat Sources/ --config BuildTools/.swiftformat
   swiftlint lint --fix --config "Debug App/.swiftlint.yml"
   swiftlint lint --config "Debug App/.swiftlint.yml"
   ```
2. **Review changes**: `git diff` to verify all changes are intentional
3. **Stage and commit** any remaining changes (conventional commit format)
4. **Push** the branch: `git push -u origin HEAD`
5. **Create the PR** using `gh pr create`:
   - Title: short (<70 chars), conventional commit style
   - Body: use the PR template from `.github/pull_request_template.md`
   - Include Jira ticket reference (`CHKT-XXXX`) if provided
   - Base branch: `master`
6. **Return the PR URL**
