---
name: create-pr
description: Create a pull request with proper Primer conventions
disable-model-invocation: true
argument-hint: "[optional-jira-ticket]"
---

Create a pull request for the current branch. Jira ticket: $ARGUMENTS

## Workflow

1. **Run code quality on modified files only**:
   ```bash
   # Get Swift files changed on this branch vs master
   git diff --name-only master...HEAD -- '*.swift' | xargs -I {} swiftformat {} --config BuildTools/.swiftformat
   git diff --name-only master...HEAD -- '*.swift' | xargs -I {} swiftlint lint --fix --config "Debug App/.swiftlint.yml" --path {}
   swiftlint lint --config "Debug App/.swiftlint.yml"
   ```
2. **Code review**: Use the Agent tool to launch the `swift-reviewer` subagent to review all Swift files changed on this branch (`git diff --name-only master...HEAD -- '*.swift'`). Present the review findings to the user. If CRITICAL or HIGH severity issues are found, stop and ask the user how to proceed before continuing.
3. **Review changes**: `git diff` to verify all changes are intentional
4. **Stage and commit** any remaining changes (conventional commit format)
5. **Push** the branch: `git push -u origin HEAD`
6. **Capture screenshots** (if UI changes): Follow the UI Verification steps in CLAUDE.md to capture screenshots for the PR body
7. **Read the PR template**: Read `.github/pull_request_template.md`
8. **Create the PR** using `gh pr create`:
   - Title: short (<70 chars), conventional commit style
   - Body: fill in each section of the PR template:
     - **Description**: Jira ticket reference (`ACC-XXXX`) + summary of changes + any breaking changes
     - **Manual Testing**: steps to verify the changes, or remove section if N/A
     - **Screenshots**: embed simulator screenshots captured in step 6, or remove section if no UI changes
     - **Contributor Checklist**: check applicable items
   - Base branch: Determine by checking `git log --oneline --graph` to find the branch this was created from. If unclear, ask the user. Common bases: `master`, `feature/checkout-components`
   - **Never** include Co-Authored-By or signed-off-by lines
   - If no Jira ticket was provided as argument, ask the user for it
9. **Return the PR URL**
