---
name: DefaultSelectCountryScope testing approach
description: How to test DefaultSelectCountryScope — no mock dependencies needed, country data depends on locale/bundled JSON
type: feedback
---

`DefaultSelectCountryScope` can be tested with nil `cardFormScope` and `checkoutScope` since selection just forwards to `cardFormScope?.updateCountryCode()` and cancel is a no-op. The scope loads countries from `CountryCode.allCases` which pulls localized names from a bundled JSON file. Country availability depends on the locale environment.

**Why:** The scope has very few dependencies — it's mostly self-contained logic around filtering and state management. The `@Published` `internalState` drives the `AsyncStream<PrimerSelectCountryState>` via `$internalState.values`.

**How to apply:** Use `awaitFirst(sut.state)` from `XCTestCase+Async` to get state snapshots. Search tests should verify filtering behavior by checking `filteredCountries` after calling `onSearch(query:)`. The scope is `@MainActor` so the test class needs `@MainActor` annotation.
