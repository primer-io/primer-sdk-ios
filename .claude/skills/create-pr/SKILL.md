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
2. **Review changes**: `git diff` to verify all changes are intentional
3. **Stage and commit** any remaining changes (conventional commit format)
4. **Push** the branch: `git push -u origin HEAD`
5. **Read the PR template**: Read `.github/pull_request_template.md`
6. **Create the PR** using `gh pr create`:
   - Title: short (<70 chars), conventional commit style
   - Body: fill in each section of the PR template:
     - **Description**: Jira ticket reference (`CHKT-XXXX`) + summary of changes + any breaking changes
     - **Manual Testing**: steps to verify the changes, or remove section if N/A
     - **Screenshots**: include if UI changes, or remove section if N/A
     - **Contributor Checklist**: check applicable items
   - Base branch: Determine by checking `git log --oneline --graph` to find the branch this was created from. If unclear, ask the user. Common bases: `master`, `feature/checkout-components`
   - **Never** include Co-Authored-By or signed-off-by lines
   - If no Jira ticket was provided as argument, ask the user for it
7. **Return the PR URL**
