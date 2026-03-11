---
name: create-pr
description: Create a pull request with proper Primer conventions
disable-model-invocation: true
argument-hint: "[optional-jira-ticket]"
---

Create a pull request for the current branch. Jira ticket: $ARGUMENTS

## Workflow

1. **Determine the base branch**: Run `git log --oneline --graph --all --decorate -20` and inspect the branch topology to find the parent branch (e.g. `master`, `feature/checkout-components`). Store it as `BASE_BRANCH` for the steps below. If unclear, ask the user.
2. **Run code quality on modified files only**:
   ```bash
   # Get Swift files changed on this branch vs BASE_BRANCH
   git diff --name-only $BASE_BRANCH...HEAD -- '*.swift' | xargs -I {} swiftformat {} --config BuildTools/.swiftformat
   git diff --name-only $BASE_BRANCH...HEAD -- '*.swift' | xargs -I {} swiftlint lint --fix --config "Debug App/.swiftlint.yml" --path {}
   swiftlint lint --config "Debug App/.swiftlint.yml"
   ```
3. **Code review**: Use the Agent tool to launch the `swift-reviewer` subagent to review all Swift files changed on this branch (`git diff --name-only $BASE_BRANCH...HEAD -- '*.swift'`). Present the review findings to the user. If CRITICAL or HIGH severity issues are found, stop and ask the user how to proceed before continuing.
4. **Review changes**: `git diff` to verify all changes are intentional
5. **Stage and commit** any remaining changes (conventional commit format: aim for ~50 char subject, body wraps at 72)
6. **Push** the branch: `git push -u origin HEAD`
7. **Capture screenshots** (if UI changes): Follow the UI Verification steps in CLAUDE.md to capture screenshots for the PR body
8. **Read the PR template**: Read `.github/pull_request_template.md`
9. **Create the PR** using `gh pr create`:
   - Title: conventional commit style (aim for ~50 chars, max 72)
   - Body: fill in each section of the PR template:
     - **Description**: Jira ticket reference (`ACC-XXXX`) + summary of changes + any breaking changes
     - **Manual Testing**: steps to verify the changes, or remove section if N/A
     - **Screenshots**: embed simulator screenshots captured in step 7, or remove section if no UI changes
     - **Contributor Checklist**: check applicable items
   - Base branch: use `BASE_BRANCH` from step 1
   - **Never** include Co-Authored-By or signed-off-by lines
   - If no Jira ticket was provided as argument, ask the user for it
10. **Return the PR URL**
