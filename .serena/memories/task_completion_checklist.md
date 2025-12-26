# Task Completion Checklist

When completing a development task on PrimerSDK, follow this checklist to ensure quality and consistency:

## 1. Code Quality

### Formatting
- [ ] Run SwiftFormat on modified files: `swiftformat <files> --config BuildTools/.swiftformat`
- [ ] Alternatively, rely on pre-commit hook (installed via `make hook`)
- [ ] Verify no formatting issues: `swiftformat . --config BuildTools/.swiftformat --lint`

### Code Review
- [ ] Ensure code follows project conventions (see `code_style_and_conventions.md`)
- [ ] Add appropriate MARK comments for organization
- [ ] Include proper access control modifiers (public/internal/private)
- [ ] Add file headers to new files with copyright notice

## 2. Testing

### Unit Tests
- [ ] Write or update unit tests for new/modified functionality
- [ ] Run SDK tests: `bundle exec fastlane test_sdk`
- [ ] Ensure all tests pass
- [ ] Check test coverage for critical paths

### Integration Tests
- [ ] Test with Debug App if UI changes were made
- [ ] Run Debug App tests: `bundle exec fastlane test_debug_app`
- [ ] Verify functionality in Debug App manually if needed

## 3. Documentation

### Code Documentation
- [ ] Add Swift doc comments to public APIs
- [ ] Include usage examples for complex features
- [ ] Update inline comments for clarity

### Project Documentation
- [ ] Update README.md if user-facing features changed
- [ ] Update CHANGELOG.md with changes (follow existing format)
- [ ] Update Contributing.md if development workflow changed

## 4. Dependencies

### Package Management
- [ ] If dependencies changed, update Package.swift
- [ ] If CocoaPods dependencies changed, update PrimerSDK.podspec
- [ ] Test both SPM and CocoaPods installation methods
- [ ] Run `swift package resolve` to update Package.resolved

## 5. Git & CI

### Commits
- [ ] Stage changes: `git add <files>`
- [ ] Commit with clear message following conventional commits format
  - Examples: `feat:`, `fix:`, `chore:`, `docs:`, `test:`
- [ ] Pre-commit hook will auto-format Swift files

### Pull Request
- [ ] Create PR against `master` branch
- [ ] Ensure PR title is descriptive
- [ ] Fill out PR description with:
  - Summary of changes
  - Testing performed
  - Any breaking changes
  - Related issues
- [ ] Wait for CI checks to pass
- [ ] Run Danger checks: `bundle exec fastlane danger_check`
- [ ] Address review feedback

## 6. Integration Verification

### SDK Integration
- [ ] Verify CocoaPods integration: `pod spec lint PrimerSDK.podspec`
- [ ] Verify SPM integration builds correctly
- [ ] Check minimum iOS version compatibility (iOS 13.1+)

### Compatibility
- [ ] Test on minimum supported iOS version (13.1)
- [ ] Test on latest iOS version
- [ ] Verify both simulator and real device if possible

## 7. Additional Checks

### Breaking Changes
- [ ] Document any breaking API changes
- [ ] Update migration guide if needed
- [ ] Bump version appropriately (major.minor.patch)

### Performance
- [ ] Check for any performance regressions
- [ ] Profile memory usage if significant changes made
- [ ] Verify no retain cycles in new code

### Accessibility
- [ ] Add accessibility identifiers to UI elements
- [ ] Test VoiceOver if UI components added/modified
- [ ] Ensure proper color contrast

## Quick Checklist (Minimal)

For smaller changes, at minimum ensure:
1. ✅ Code is formatted (pre-commit hook handles this)
2. ✅ Tests pass: `bundle exec fastlane test_sdk`
3. ✅ Changes are committed with clear message
4. ✅ PR created with description
