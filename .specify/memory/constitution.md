<!--
Sync Impact Report - Constitution v1.0.0
========================================
Version Change: [NONE] → 1.0.0
Type: INITIAL RATIFICATION
Date: 2025-11-03

Principles Added:
- I. iOS Platform Standards (NON-NEGOTIABLE)
- II. Cross-Platform API Parity
- III. Integration Flexibility
- IV. Security & PCI Compliance (NON-NEGOTIABLE)
- V. Test Coverage & Quality Gates
- VI. Backward Compatibility & Versioning

Sections Added:
- Core Principles (6 principles)
- Technical Constraints
- Quality Standards
- Governance

Templates Requiring Updates:
✅ .specify/templates/plan-template.md - Already contains Constitution Check section aligned with these principles
✅ .specify/templates/spec-template.md - Requirements structure supports these principles
✅ .specify/templates/tasks-template.md - Task organization supports quality gates and testing discipline
✅ .specify/templates/commands/*.md - Generic guidance compatible with SDK development

Follow-up TODOs:
- None - All placeholders filled with concrete values

Rationale for v1.0.0:
This is the initial ratification of the Primer iOS SDK constitution, codifying existing
practices observed in the codebase and plan.md constitution checks. MAJOR version 1
indicates this is the first formal governance document for the project.
-->

# Primer iOS SDK Constitution

## Core Principles

### I. iOS Platform Standards (NON-NEGOTIABLE)

All SDK features MUST adhere to Apple's platform requirements and ecosystem conventions:

- **Minimum iOS version**: iOS 13.0+ (SDK baseline), iOS 15.0+ for CheckoutComponents
- **Language compliance**: Swift 6.0+ with strict concurrency checking enabled
- **Code quality enforcement**: SwiftLint configuration MUST be respected:
  - Line length: 150 characters (warning threshold)
  - File length: 500 lines (warning), 800 lines (error threshold)
  - Function body length: 60 lines (warning), 100 lines (error threshold)
  - Cyclomatic complexity: 12 (warning), 20 (error threshold)
- **Distribution channels**: CocoaPods and Swift Package Manager (SPM) MUST both be supported without feature parity gaps
- **Apple Human Interface Guidelines**: UI components MUST follow platform design patterns (accessibility, Dynamic Type, VoiceOver, keyboard navigation)

**Rationale**: Primer SDK is a merchant-facing library that must integrate seamlessly into diverse iOS applications. Platform compliance ensures merchant apps remain App Store compliant and provides consistent user experience across integrations.

**Enforcement**: SwiftLint runs in CI/CD pipeline; PRs failing linting checks are automatically blocked. Xcode build settings enforce Swift 6.0+ language mode.

### II. Cross-Platform API Parity

API design and feature capabilities MUST maintain conceptual parity with Primer's Android SDK:

- **Scope-based architecture**: CheckoutComponents use identical scope naming and state management patterns across iOS (Swift) and Android (Kotlin)
- **Integration approaches**: All three integration methods (Drop-In UI, Headless, CheckoutComponents) MUST have Android equivalents with matching capabilities
- **Identifier naming**: Accessibility identifiers, analytics event names, and internal component IDs MUST use platform-agnostic naming schemes to enable cross-platform test scripts
- **Documentation structure**: Feature documentation MUST mirror Android SDK structure for consistency in merchant onboarding

**Exceptions**: Platform-specific implementations are acceptable when dictated by OS capabilities (e.g., iOS VoiceOver vs Android TalkBack, SwiftUI vs Jetpack Compose UI frameworks). In such cases, *functional outcome* must remain equivalent even if *implementation* differs.

**Rationale**: Primer serves merchants with multi-platform applications. API consistency reduces integration effort, allows shared test automation infrastructure, and prevents merchant confusion when consulting documentation.

**Enforcement**: Architecture Decision Records (ADRs) MUST be created for any new CheckoutComponents API, with explicit cross-platform parity review. Android team consulted during design phase for scope-based features.

### III. Integration Flexibility

SDK architecture MUST support three distinct integration patterns without forcing merchants into a specific approach:

1. **Drop-In UI (Universal Checkout)**: Fully managed UI requiring minimal merchant code (single `showUniversalCheckout()` call)
2. **Headless**: No UI provided; merchants build custom interfaces while SDK handles payment logic, tokenization, and 3DS
3. **CheckoutComponents**: Modular SwiftUI components with customization hooks via `customContent` parameter

**Constraints**:
- Features MUST NOT introduce cross-dependencies between integration approaches (e.g., Headless API cannot depend on Drop-In UI code)
- Breaking changes to public APIs require MAJOR version bump (SemVer)
- Deprecation period for public APIs: minimum 2 MINOR versions before removal
- Internal APIs (prefixed `Internal/` in folder structure) may evolve without deprecation process

**Customization Philosophy**:
- Drop-In UI: Theming via `PrimerSettings` (limited customization by design)
- CheckoutComponents: Full control via SwiftUI composition and `customContent` closures
- Headless: Complete UI control; SDK provides state management and payment orchestration only

**Rationale**: Different merchants have different UX requirements. A fintech startup may prefer Drop-In UI for rapid launch, while an established brand may demand pixel-perfect CheckoutComponents customization.

**Enforcement**: PR reviews MUST verify no unintended coupling between integration approaches. Module dependency graph audited quarterly.

### IV. Security & PCI Compliance (NON-NEGOTIABLE)

All SDK code MUST maintain PCI DSS Level 1 compliance and protect sensitive payment data:

- **No PII in logs**: Payment card numbers, CVV, cardholder names, PII MUST NEVER appear in logs, analytics events, or accessibility strings
- **Tokenization-only**: Raw payment data MUST only be transmitted to Primer's tokenization endpoint; never stored locally or logged
- **Sensitive data masking**: UI components displaying payment data (e.g., saved cards) MUST mask sensitive fields:
  - Card numbers: Show last 4 digits only (e.g., "••••1234")
  - VoiceOver announcements: Mask even last 4 digits in audio output (announced as "card ending in ••••") to prevent eavesdropping
- **Accessibility identifiers**: MUST be semantic and data-independent (e.g., `CheckoutComponents_CardForm_CardNumber_Field`, NOT `card_field_4111111111111111`)
- **Analytics events**: May log state changes (e.g., "payment_form_opened") but MUST NOT include payment data or PII in event payloads
- **3DS handling**: Delegate to certified Netcetera SDK (via `primer-sdk-3ds-ios` dependency); do NOT implement custom 3DS challenge flows

**Audit Requirements**:
- Annual PCI compliance audit by Primer's security team
- Quarterly code review of logging statements in PRs
- Automated checks: `grep -r "cardNumber\|cvv\|cardholder" Sources/` in CI/CD to flag suspicious logging

**Rationale**: PCI compliance is non-negotiable for payment SDKs. Violations can result in merchant fines, loss of processor relationships, and reputational damage to Primer.

**Enforcement**: Security violations block PR merges. PCI audit findings trigger immediate hotfix releases.

### V. Test Coverage & Quality Gates

Comprehensive testing MUST be maintained across unit, integration, and UI test layers:

**Test Requirements**:
- **Unit tests**: Required for all business logic, state machines, data transformations, and internal services
  - Target coverage: ≥80% line coverage for Core/ and CheckoutComponents/ modules
  - Mock external dependencies (network, 3DS SDK, analytics)
- **Integration tests**: Required for critical flows involving multiple components:
  - Payment method selection → card form → tokenization → success/error handling
  - 3DS authentication flows (happy path + edge cases)
  - Headless API contract tests (state transitions, delegate callbacks)
- **UI tests**: Required for accessibility compliance and visual regression:
  - VoiceOver announcement verification (XCUITest with accessibility queries)
  - Dynamic Type scaling validation at all 12 text size categories
  - Keyboard navigation flows (Tab order, focus indicators, no keyboard traps)
  - Accessibility Inspector automated audits in CI/CD
- **Manual testing checklist**: Required for major releases:
  - VoiceOver walkthrough completing full payment flow
  - Testing on oldest supported iOS version (13.0) and latest iOS beta
  - CocoaPods and SPM installation smoke tests

**Quality Gates** (blocking PR merge):
- ✅ All tests pass on CI/CD (Xcode Cloud or GitHub Actions)
- ✅ SwiftLint passes with zero errors (warnings acceptable with justification)
- ✅ No new accessibility violations detected by Accessibility Inspector
- ✅ Code review approval from at least one iOS team member

**Rationale**: Primer SDK is integrated into production merchant apps processing real payments. Test failures in production cause merchant revenue loss and support escalations. Proactive quality gates prevent regressions.

**Enforcement**: CI/CD pipeline enforces automated checks. Manual testing checklist verified by QA lead before major release tags.

### VI. Backward Compatibility & Versioning

SDK versioning MUST follow Semantic Versioning (SemVer: MAJOR.MINOR.PATCH) with strict compatibility guarantees:

**Version Bump Rules**:
- **MAJOR**: Breaking changes to public APIs (method signature changes, removed classes, behavior changes requiring merchant code updates)
  - Examples: Removing `Primer.shared.showUniversalCheckout()`, changing delegate method signatures, renaming public enums
  - Deprecation: MAJOR bumps MUST be preceded by at least 2 MINOR versions with deprecation warnings
- **MINOR**: Additive changes (new features, new APIs, new integration options) that are backward compatible
  - Examples: Adding new CheckoutComponents scope, new payment method support, new customization options
  - Internal improvements without public API impact (e.g., accessibility enhancements to existing components)
- **PATCH**: Bug fixes, performance improvements, security patches with no API changes
  - Examples: Fixing crash in edge case, correcting localization string, optimizing animation performance

**Backward Compatibility Commitments**:
- Public APIs MUST remain functional across MINOR and PATCH versions
- Deprecated APIs MUST continue working (with deprecation warnings) for minimum 2 MINOR versions before removal
- Internal APIs (in `Internal/` folders) may change without notice; merchants MUST NOT depend on internal APIs
- Accessibility identifiers (used in UI tests) MUST remain stable across MINOR/PATCH versions; changes require MAJOR bump

**Breaking Change Documentation**:
- CHANGELOG.md MUST document all breaking changes with migration guide
- Migration guides MUST include code examples showing before/after for common use cases
- For MAJOR bumps, publish migration blog post on Primer Developer Portal

**Rationale**: Merchants integrate Primer SDK into production apps with infrequent update cycles. Breaking changes cause merchant engineering work and may block Primer feature adoption. Strict SemVer adherence allows merchants to assess update risk.

**Enforcement**: PR reviews MUST flag breaking changes and enforce correct version bump. Release manager verifies CHANGELOG completeness before tagging releases.

## Technical Constraints

### Supported Platforms
- **iOS**: 13.0+ (SDK baseline), 15.0+ for CheckoutComponents due to SwiftUI requirements
- **Swift**: 6.0+ with strict concurrency enabled
- **Xcode**: 15.0+ (matches Swift 6.0 requirement)
- **Architecture**: arm64 (iOS devices), x86_64 + arm64 (iOS Simulator)

### Forbidden Dependencies
- MUST NOT include blockchain/cryptocurrency libraries (outside Primer's payment scope)
- MUST NOT depend on specific merchant app frameworks (e.g., Firebase, Analytics SDKs) to avoid version conflicts
- MUST NOT include large binary assets (>5MB) that bloat merchant app size; lazy-load resources if needed

### Performance Budgets
- **Initialization time**: Primer.shared.configure() MUST complete in <200ms on iPhone SE (2020)
- **UI responsiveness**: 60fps target for checkout UI animations; graceful degradation to 30fps acceptable during complex layout (e.g., Dynamic Type AX5 sizing)
- **Binary size**: SDK .framework size MUST remain <15MB uncompressed to minimize impact on merchant app size

## Quality Standards

### Code Review Requirements
- All PRs MUST be reviewed by at least one iOS team member before merge
- PRs modifying public APIs require approval from iOS SDK architect
- Security-sensitive code (PCI scope: tokenization, 3DS, logging) requires security team review

### Documentation Standards
- Public APIs MUST have Swift DocC comments with usage examples
- CLAUDE.md MUST be updated when project structure or key patterns change
- Feature specifications MUST exist in `specs/[###-feature-name]/` before implementation begins
- Accessibility requirements MUST be documented for all UI components with code examples (per FR-035 from current accessibility spec)

### Continuous Integration
- Unit tests MUST pass on both oldest supported iOS (13.0) and latest iOS beta
- SwiftLint MUST pass with zero errors
- Build MUST succeed for both CocoaPods and SPM distribution
- Accessibility Inspector automated audit MUST show zero errors

## Governance

### Amendment Process
1. Propose constitution change via pull request to `.specify/memory/constitution.md`
2. PR description MUST include:
   - Rationale for change (what problem does it solve?)
   - Impact analysis (which principles/sections affected?)
   - Version bump justification (MAJOR/MINOR/PATCH per SemVer)
3. Constitution amendments require approval from:
   - iOS SDK architect (for technical principles)
   - Security lead (for security/PCI principles)
   - Product manager (for integration flexibility / versioning principles)
4. Approved amendments take effect immediately upon merge; all in-flight features MUST comply with updated constitution

### Compliance Verification
- **PR reviews**: Reviewers MUST verify constitution compliance before approval
- **Feature specs**: `/speckit.plan` command includes Constitution Check gate that MUST pass before implementation begins
- **Quarterly audits**: iOS team conducts constitution compliance review of recent PRs to identify systemic violations
- **PCI audits**: Annual third-party security audit verifies compliance with Principle IV (Security & PCI Compliance)

### Complexity Justification
- Exceptions to principles (e.g., violating platform standards for specific merchant request) MUST be documented in Architecture Decision Record (ADR) with:
  - Business justification (why is exception necessary?)
  - Risk assessment (what compliance/compatibility risks introduced?)
  - Mitigation plan (how will risks be managed?)
  - Expiration criteria (when will exception be removed?)

### Runtime Development Guidance
- This constitution governs strategic architectural decisions and non-negotiable constraints
- For day-to-day development patterns and coding conventions, refer to:
  - `CLAUDE.md` - AI assistant guidance for this repository
  - `Debug App/.swiftlint.yml` - Enforced code style rules
  - `Sources/PrimerSDK/Classes/CheckoutComponents/CLAUDE.md` - CheckoutComponents-specific patterns
- When guidance conflicts arise: Constitution > Project CLAUDE.md > SwiftLint config

**Version**: 1.0.0 | **Ratified**: 2025-11-03 | **Last Amended**: 2025-11-03
