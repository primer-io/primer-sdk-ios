# CheckoutComponents Code Review Execution Prompt

## Task Overview
You are tasked with conducting a comprehensive code review of the CheckoutComponents framework in the Primer iOS SDK. This is a production-ready payment integration framework that requires thorough evaluation for security, performance, code quality, and API consistency.

## Your Role
You are acting as a senior iOS engineer with expertise in:
- SwiftUI and modern iOS development
- Payment systems and PCI compliance
- Security best practices
- Performance optimization
- Cross-platform SDK development

## Review Scope
Review all code under `/Sources/PrimerSDK/Classes/CheckoutComponents/` following the provided plan in `CheckoutComponents_Code_Review_Plan.md`.

## Execution Instructions

### Phase 1: Initial Setup and Architecture Review
1. Read the `CheckoutComponents_Code_Review_Plan.md` document completely
2. Familiarize yourself with the CLAUDE.md documentation in the repository
3. Begin with Section 3 (Architecture Overview Assessment) of the plan
4. Review each architectural component systematically:
   - Examine scope-based architecture implementation
   - Evaluate the actor-based DI container
   - Analyze AsyncStream state management patterns
   - Assess protocol design and module boundaries

### Phase 2: Feature-by-Feature Deep Dive
Following Section 4 of the plan, conduct detailed reviews of:
1. **Card Form Implementation** - Focus on validation, input handling, and co-badged card support
2. **Country Selection** - Evaluate search performance and data management
3. **Payment Method Selection** - Review layout flexibility and resource loading
4. **Billing Address Collection** - Verify country-specific rules and field ordering

### Phase 3: Security and Performance Analysis
Using Section 5 criteria:
1. Conduct PCI compliance verification
2. Check for security vulnerabilities
3. Measure performance against provided benchmarks
4. Document any security or performance concerns

### Phase 4: Code Quality and API Parity
1. Apply Section 6 metrics for code quality assessment
2. Use Section 7 guidelines to verify Android API parity
3. Document any deviations or inconsistencies

## Output Requirements

### For Each Finding:
Use the Issue Tracking Format from Section 8.2:
```
ISSUE-[NUMBER]:
File: [Filepath:LineNumber]
Severity: [CRITICAL/HIGH/MEDIUM/LOW]
Category: [Security/Performance/Architecture/Quality/API Parity]
Description: [Clear description of the issue]
Recommendation: [Actionable fix or improvement]
Code Reference: [Relevant code snippet if applicable]
```

### Component Reviews:
Complete the Component Review Template (Section 8.3) for each major component.

### Final Deliverable:
Produce a summary report following Section 8.4 structure with:
1. Executive summary of findings
2. Categorized technical issues
3. Prioritized recommendations
4. Technical debt inventory

## Review Priorities
1. **CRITICAL**: Security vulnerabilities, PCI compliance violations
2. **HIGH**: Performance issues, API parity breaks, memory leaks
3. **MEDIUM**: Code quality issues, missing tests, documentation gaps
4. **LOW**: Style inconsistencies, minor optimizations

## Special Focus Areas
- **Security**: Any handling of payment card data must be PCI compliant
- **Memory Management**: Check for retain cycles in AsyncStream closures
- **API Parity**: Every public API must match Android equivalent
- **Error Handling**: Consistent error types and user-friendly messages
- **Performance**: SwiftUI rendering must meet 60fps requirement

## Review Methodology
1. Start with static code analysis of each file
2. Trace data flow through the system
3. Identify integration points and dependencies
4. Verify against requirements and best practices
5. Document findings immediately using provided templates

## Important Considerations
- This is production code handling sensitive payment data
- Security issues take highest priority
- Performance impacts user experience directly
- API consistency affects cross-platform developers
- All findings must be actionable and specific

Begin your review by confirming you understand these instructions and have access to the review plan document. Then proceed with Phase 1 of the review process.