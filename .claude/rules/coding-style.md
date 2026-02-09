---
paths:
  - "Sources/**/*.swift"
  - "Tests/**/*.swift"
---

# Swift Coding Style

These rules reflect team conventions enforced during code review. Follow them when writing or modifying Swift code.

## Swift Syntax
- **Shorthand optional binding**: `if let x { }` not `if let x = x { }`. Same for `guard let self else { return }`. Don't rename during unwrap.
- **Omit `return`** in single-expression computed properties, closures, and `get` blocks.
- **Omit unnecessary `self`**: only use `self` where the compiler requires it. In `Task`, use `[self] in` capture list instead of `self.` everywhere.
- **`[self]` over `[weak self]`** in `Task` closures when there is no retain cycle risk.
- **Use `let x = if/switch` expression syntax** (Swift 5.9+) instead of declaring `var` then assigning in each branch.
- **Implicit member expressions**: use `.foo` not `Type.foo` when the type is inferrable (e.g. `.center`, `.degrees(180)`, `.primary`).
- **Functional references**: `.map(String.init)` not `.map { String($0) }`, `onCvvChange: scope.updateCvvInput` not `{ scope.updateCvvInput($0) }`.
- **`optional.map`** for transformations: `method.backgroundColor.map(Color.init)` not `if let` unwrap-then-wrap.
- **Nil coalescing** for defaults: `value ?? .fallback` not `if let value { value } else { .fallback }`.
- **`isEmpty`** over `count == 0`.
- **Prefer standard library**: `contains(where:)`, `map`, `compactMap`, `filter` over manual loops with flags.
- **Omit unnecessary imports**: don't import `Foundation` or `UIKit` if `SwiftUI` is already imported.
- **Omit unnecessary `Group`**: only use `Group` when applying a shared modifier.

## Member Ordering (within types)
1. Stored properties — ordered by access: public → default (internal) → private(set) → private
2. Computed properties — same access order
3. Initializers
4. Functions — ordered by access: public → default (internal) → private

Within the same access level, protocol conformance properties come first, then other properties.

## Access Control
- **Default to `private`** for all properties, methods, and types. Widen access only when the compiler requires it.
- **Never write `internal`** — it's the default access level and is redundant.
- **`private(set)` is redundant** on properties of already-private types.
- **No redundant access in extensions**: if an extension is `private`, its members must not repeat `private`.
- **`@discardableResult`** on functions whose return value is often unused (registration, builders, chainable methods).

## SwiftUI Views
- **Use `func make...() -> some View`** for extracted view pieces. Use `@ViewBuilder` only when the function returns multiple views conditionally.
- **Extract complex booleans**: pull multi-condition `if` expressions into named computed properties for readability.
- **Pass function references directly**: `Button(action: scope.cancel)` not `Button { scope.cancel() }`.

## Code Minimalism
- **No redundant comments**: only comment non-obvious "why", never "what the code does". Doc comments that restate the function/class name are not allowed.
- **No verbose `// MARK:`** for trivial sections (2-3 simple properties don't need a MARK).
- **Inline single-use variables**: if a variable is used only once on the next line, inline it.
- **No hardcoded values**: extract strings/numbers into constants. In tests, use `TestData` as single source of truth (exception: assertion expected values and analytics error messages).
- **Use ternaries** for simple conditional assignments.
- **Combine guards** when they share the same exit action: `guard let a, let b else { return }`. Keep them separate if different conditions need different handling.
- **No redundant methods** that just return a stored property — let callers access the property directly.
- **No redundant property defaults** when the initializer already provides them.
- **Non-optional with default** over optional with internal fallback: `func process(type: String = "PAYMENT_CARD")` not `func process(type: String? = nil)` with `?? "PAYMENT_CARD"` inside.
- **No leftover debug artifacts**: remove `print` statements and commented-out code.
- **Typealias** for complex/repeated type signatures, and tuples with more than 2 elements.

## Type Design
- **`final` by default**: all classes should be `final` unless explicitly designed for inheritance.
- **`let` over `var`** for properties only assigned in `init` — use `var` only when the property is reassigned later.
- **Caseless `enum`** for namespace-only types (no instances needed).
- **One meaningful type per file**: each type gets its own file.
- **Check for existing utilities** before creating new helpers or extensions.
- **Don't wrap accessible properties** in convenience methods — let callers access them directly.

## Test Code
- Test properties (`sut`, mocks) should be **`private`**.
- Mock classes should be **`final`**.
- Put **`@MainActor` on the test class**, not on individual test methods.
- Every test must **assert something** — no test should just call code without verifying results.
- Use **`CaseIterable` + `allCases`** for exhaustive enum testing.
- Use helpers to reduce boilerplate across similar tests.
- Use `TestData` as single source of truth for test constants (exception: assertion expected values and analytics error messages).
