# CheckoutComponents PR Review Findings

**Date:** 2026-03-31
**Reviewer:** swift-reviewer agents (Opus)
**Scope:** PRs #1630–#1645 (cc-01 through cc-16)
**PRs 01 & 16 skipped** (no Swift files — build config and localization strings only)

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 8 |
| HIGH | 63 |
| MEDIUM | 141 |
| LOW | 60 |
| **Total** | **272** |

### Top Issues by Theme

1. **Excessive `public` access on internal types** — ~30+ types in `Internal/` directories marked `public` (DI framework, scopes, analytics models, validation types). This pollutes the merchant-facing API surface.
2. **Missing `final` on classes** — Dozens of classes missing `final` per coding style rules.
3. **Emoji in log messages** — Pervasive across analytics, logging, navigation, scopes.
4. **Inconsistent error handling** — Some paths use `handled(error:)`, others use `ErrorHandler.handle`, others swallow errors with `try?`.
5. **Hardcoded strings** — English fallbacks, error IDs, validation messages not using localization/constants.
6. **Code duplication** — Scope creation boilerplate (8x), bridge vs repository, CardFormScreen vs CardFormFieldsView.
7. **Missing `Sendable` conformances** — Analytics payload types crossing actor boundaries.
8. **Namespace structs should be caseless enums** — `PrimerFont`, `PrimerSpacing`, `AnimationConstants`, etc.

---

## PR 02: DI Container Framework (#1631)
**Files reviewed:** 26

### CRITICAL

1. **`Tests/Primer/CheckoutComponents/DI/RetentionPolicyTests.swift:284-340`** — Tests do not exercise the real DI framework. File defines a private `DIContainer` class that shadows the actual `PrimerSDK.DIContainer`. All 14 tests run against a local mock with force unwraps (`as! T`), providing zero coverage of production `Container`, `RetentionStrategy`, `SingletonStrategy`, `WeakStrategy`, `TransientStrategy`, and `ContainerRetainPolicy.makeStrategy()`.

2. **`Sources/.../DI/Framework/Container.swift:315-333`** — `resolveBatch` has false circular dependency risk. Child tasks call `self.resolve()` on the actor. If two batch items share a dependency, the first task's resolution may be suspended mid-chain (key still in `resolutionStack`), and the second task entering resolve for the same type sees it and throws `circularDependency` erroneously.

### HIGH

3. **`Container.swift:62`** — `Container` is `public actor` but should be internal. The core DI implementation detail is exposed to merchants. Only `ContainerProtocol` should be public.

4. **`Container.swift:86`** — `ContainerRegistrationBuilderImpl` is `public class` — should be internal. Implementation detail.

5. **`ContainerDiagnostics.swift:9,37,43,50`** — `ContainerDiagnostics`, `HealthStatus`, `HealthIssue`, `ContainerHealthReport` all `public` — should be internal.

6. **`ContainerError.swift:9`** — `ContainerError` is `public enum` — should be internal. DI errors should map to `PrimerError` at boundaries.

7. **`TypeKey.swift:10`** — `TypeKey` is `public struct` — should be internal. Its `Codable` `init(from:)` sets `typeId = ObjectIdentifier(NSObject.self)`, meaning all deserialized keys collide.

8. **`ContainerRetainPolicy.swift:10`** — `public enum` with `Codable` — should be internal, no use case for persistence.

9. **`DependencyScope.swift:9`** — `public protocol` — should be internal.

10. **`Factory.swift:10,19`** — `Factory` and `SynchronousFactory` are `public protocol` — should be internal.

11. **`Container.swift:141-142`** — `instances` and `weakBoxes` are internal access on an actor. Should be `private` with dedicated accessor methods.

12. **`DependencyScope.swift:11`** — `setupContainer` takes concrete `Container` instead of `any ContainerProtocol`.

### MEDIUM

13. **`DIContainter+SwiftUI.swift`** — Filename typo: "DIContainter" should be "DIContainer". Also has duplicate header block.

14. **`Container.swift:421-426`** — Duplicate `registerFactory` method shadows protocol extension version.

15. **`Factory.swift:81,109` and `Container.swift:203`** — Force unwrap `name!` after nil check. Use `if let name` binding.

16. **`Container.swift:86`** — `ContainerRegistrationBuilderImpl` not `final class`.

17. **`Container.swift:10`** — `WeakBox` not `final`.

18. **`Container.swift:19`** — `SyncCache` not `final`.

19. **`Container.swift:44`** — `ThreadSafeContainer` not `final`.

20. **`SwiftUI+DI.swift`** — Empty file, only contains a comment. Delete.

21. **`Tests/.../DI/SwiftUIDITests.swift`** — Empty test class with zero test methods. Delete.

22. **`ContainerProtocol.swift:9`** — Non-standard en-dash `–` in MARK comments. Use ASCII hyphen.

23. **`ContainerProtocol.swift:51-62`** — `RegistrationBuilder.with` methods lack `@discardableResult`.

24. **`Container.swift:8`** — `swiftlint:disable file_length` on ~480-line file. Consider splitting.

25. **`ContainerDiagnostics.swift:86-237`** — Over-engineered DEBUG-only diagnostics (~150 lines).

26. **`ContainerDiagnostics.swift:57-78`** — Emoji strings in `printReport()`.

27. **`Container.swift:192-204`** — `registerIfNeeded` uses force unwrap `name!`.

28. **`Tests/Primer/DependencyInjectionTests.swift:13-15`** — Test helper types lack `final` and `private`.

### LOW

29. **`ContainerDiagnostics.swift:93`** — Unused `logger` parameter in `InstrumentedContainer.init`.

30. **`TypeKey.swift:45`** — `debugDescription` without `CustomDebugStringConvertible` conformance.

31. **`Container.swift:10-14`** — `WeakBox` parameter `inst` abbreviated. Use `instance`.

32. **`ContainerDiagnostics.swift:37-41`** — `HealthStatus.critical` never used in production.

33. **`Container.swift:382-404`** — `reset` generic parameter forces homogeneous ignore list.

34. **`Tests/.../ContainerDiagnosticsTests.swift:436`** — Tests only assert "does not crash".

35. **`Container.swift:315`** — Comment says "parallel" but resolution is serialized via actor.

---

## PR 03: SDK Existing File Modifications (#1632)
**Files reviewed:** 33

### CRITICAL

1. **`PrimerDelegate.swift:380`** — `preconditionFailure()` will crash if async `primerDidFailWithError` is called when `sdkIntegrationType == .checkoutComponents`. The `.checkoutComponents` case was added to `primerWillCreatePaymentWithData` but NOT to `primerDidFailWithError`. Latent crash.

### HIGH

2. **`AnalyticsEvent.swift:767-769`** — `SDKProperties.encode(to:)` encodes `sdkSettings` twice (lines 767 and 769) and never encodes `sdkIntegrationType`. All analytics payloads will be missing the integration type. Fix: replace duplicate encode with `sdkIntegrationType`.

3. **`PrimerLogger.swift:99-127`** — New `error(message:error:userInfo:)` creates hard dependency from core SDK logging to CheckoutComponents DI types. When CC is not in use, `#if DEBUG` prints fire on every error log — noisy for Drop-In/Headless.

4. **`PrimerLogger.swift:129-150`** — New `public func info(message:event:userInfo:)` is public but silently does nothing for Drop-In/Headless. Misleading API.

### MEDIUM

5. **`PrimerSettings.swift:60`** — `clientSessionCachingEnabled` new `public let` breaks auto-synthesized `Codable` decode for previously serialized settings (missing key).

6. **`PrimerTheme.swift:79-86`** — `Equatable` uses identity comparison (`===`). Misleading — two identical configs compare unequal.

7. **`PrimerSettings.swift:323-329`** — `DismissalMechanism` auto-synthesized `Codable` — rename risk.

8. **`Primer.swift:56-59`** — `FontRegistration.registerFonts()` called in `Primer.init()` — runs for ALL SDK users even without CheckoutComponents.

9. **`PrimerSettings.swift:399`** — `isInitScreenEnabled != nil ? isInitScreenEnabled! : true` should be `?? true`.

10. **`PrimerSettings.swift:448`** — Same pattern for `is3DSSanityCheckEnabled`.

11. **`PrimerSettings.swift:380-388`** — `theme` in `CodingKeys` but never encoded/decoded. Dead code.

12. **`PrimerSettings.swift:291-296`** — `CardNetworkSelectorStyle` new public enum — should be documented as public API contract.

### LOW

13. **`PrimerSettings.swift:70`** — `threeDsOptions` parameter silently ignored. Needs deprecation annotation.

14-20. Various well-documented v3.0 breaking changes, clean utility additions. No issues.

---

## PR 04: Domain Foundation (#1633)
**Files reviewed:** 36

### CRITICAL

1. **`PaymentResult.swift:20`** — `public init` on `PaymentResult` lets merchants construct payment results. Initializer should drop `public`.

### HIGH

2. **`ProcessApplePayPaymentInteractor.swift:53`** — `paymentResponse.id ?? ""` silently coerces nil payment ID to empty string. Should throw.

3. **`ProcessWebRedirectPaymentInteractor.swift:33`** — Default parameter `UIApplication.shared` accessed at init time — can crash off main thread or in extension context.

4. **`ProcessFormRedirectPaymentInteractor.swift:45,66,92,97`** — Uses `ErrorHandler.handle(error:)` directly instead of `handled(error:)` pattern.

5. **`InternalPaymentMethod.swift:69-74`** — Custom `Equatable` ignores `networkSurcharges`, `configId`, `icon`, etc. Could mask real changes.

6. **`ProcessAchPaymentInteractor.swift:29`** — Not `@MainActor` despite calling `@MainActor`-isolated `AchRepository`.

7. **`ProcessKlarnaPaymentInteractor.swift:19`** — Same: not `@MainActor` but calls `@MainActor` KlarnaRepository.

### MEDIUM

8. **`CardNetworkDetectionInteractor.swift:9`** — Protocol missing `@available(iOS 15.0, *)`.

9. **`GetPaymentMethodsInteractor.swift:13`, `ProcessCardPaymentInteractor.swift:22`, `ValidateInputInteractor.swift:15`** — Same: protocols missing availability annotation.

10. **`HeadlessRepository.swift:9`** — Missing `@available(iOS 15.0, *)`.

11. **`ApplePayRequestBuilder.swift:50-53`** — Empty string fallback for `merchantName` — looks broken on Apple Pay sheet.

12. **`ProcessPayPalPaymentInteractor.swift:24`** — `PrimerInternal.shared.intent` accessed as global singleton, not injected.

13. **`PaymentResult.swift:53-59`** — No unknown/default case in `PaymentStatus.init(from:)`.

14. **`TestData+Address.swift:91-92`** — `OTPCodes.valid4Digit` and `tooShort` are identical values.

15. **`TestData+Config.swift:31`** — `enum Locale` shadows `Foundation.Locale`.

16-19. Various minor test and style issues.

### LOW

20. **`ApplePayRequestBuilder.swift:10`** — Should be caseless `enum` (only static methods).

21. **`PaymentMethodMapper.swift:48`** — `.map { mapToPublic($0) }` could be `.map(mapToPublic)`.

22-24. Minor style issues.

---

## PR 05: Validation System (#1634)
**Files reviewed:** 22

### HIGH

1. **`ValidationError.swift:9`** — `public struct` in `Internal/` directory. Should not be public or should move.

2. **`ValidationError.swift:20`** — `public enum InputElementType` nested in public struct exposes 17 cases to merchants.

3. **`ValidationService.swift:166`** — Blanket `// swiftlint:disable all`. Should be scoped to specific rule.

4. **`ValidationService.swift:48`** — `ValidationResultCache` static singleton shared across tests — 30-second TTL causes test pollution.

5. **`ExpiryDateInput.swift:42`** — Year comparison doesn't handle century rollover (2099 → "00" for 2100).

6. **`CommonValidationRules.swift:267`** — `CountryCodeRule` only validates length, accepts `"!@"`.

### MEDIUM

7. **`ValidationService.swift:108`** — `DefaultValidationService` is `public final class` in `Internal/`.

8. **`CardValidationRules.swift:41-42`** — Redundant length check (already guaranteed by preceding check).

9. **`CommonValidationRules.swift:52-68`** — `FirstNameRule`/`LastNameRule` are thin wrappers. Factory could return `NameRule` directly.

10. **`CommonValidationRules.swift:118-329`** — Many thin wrapper rules. Consider generic `OptionalRule<R>`.

11. **`ValidationService.swift:226-232`** — `CityRule` (min 2) exists but unused — `AddressFieldRule` (min 3) used instead. Inconsistent.

12. **`ValidationService.swift:228-232`** — Same for `StateRule` — defined but unused in main path.

13. **`ExpiryDateInput.swift:43-53`** — Hardcoded error strings instead of constants/localization.

14. **`CardValidationRules.swift:46-51`** — Same: hardcoded error IDs.

15-16. Test helper duplication, additional hardcoded strings.

### LOW

17-22. `count > 0` vs `isEmpty`, redundant typealias, minor test issues.

---

## PR 06: Public API Layer (#1635)
**Files reviewed:** 31

### CRITICAL

1. **`CardFormProvider.swift:61`** — Leaks internal concrete type `DefaultCardFormScope` into public View body.

2. **`PrimerPaymentMethodScope.swift:94-128`** — `PaymentMethodProtocol` is `public` and exposes `ContainerProtocol` (DI container) to merchants.

3. **`DefaultCardFormScope.swift:9-24`** — `FieldValidationStates` is `public struct` in `Internal/` directory.

### HIGH

4. **`PrimerPaymentMethodScope.swift:136`** — `PaymentMethodRegistry` singleton mutated via `reset()` in tests — test isolation risk.

5. **`PrimerPaymentMethodScope.swift:157`** — Emoji in log messages (multiple locations).

6. **`PrimerCardFormScope.swift:55-56`** — Protocol requirement duplication: `state`, `start()`, `submit()`, `cancel()`, `onBack()` already declared in parent `PrimerPaymentMethodScope`. Same pattern in all 8 payment method scope protocols.

7. **`PrimerCheckoutScope.swift:12-15`** — `BeforePaymentCreateHandler` uses callback-in-callback pattern instead of async.

### MEDIUM

8-9. Leftover change note comments ("Success screen removed", "Removed: setPaymentMethodScreen").

10. **`PrimerCardFormScope.swift:1`** — `swiftlint:disable identifier_name` at file scope instead of scoped.

11. **`PrimerEnvironment.swift:63-64`** — Doc comment example references `structuredState` — won't compile.

12. **`PrimerCardFormState.swift:62-63`** — `FieldError` has `id = UUID()` — SwiftUI diffing may not work correctly if errors are recreated.

13. **`PrimerSelectCountryScope.swift:34-38`** — `searchBar` property type is raw tuple closure — unreadable.

14. **`PrimerCardFormState.swift:276-278`** — `setError`/`clearError` public mutating on state struct — unusual pattern.

15-24. Various redundant doc comments, inconsistent return types, test style issues.

### LOW

25. **`PrimerCheckoutTheme.swift:60-221`** — `ColorOverrides` init has 34 parameters (acceptable but noted).

26-30. Minor style issues.

---

## PR 07: Design Tokens (#1636)
**Files reviewed:** 14

### HIGH

1. **`DesignTokens.swift:251-765`** — Color decoding accesses array indices `[0]-[3]` without bounds check. Crash on malformed JSON.

2. **`DesignTokensManager.swift:47-49`** — Redundant `MainActor.run` inside `@MainActor` class.

3. **`DesignTokensProcessor.swift:233-249`** — `evaluateExpression` fragile with negative numbers (e.g., `"-0.6"` letter-spacing).

### MEDIUM

4. **`DesignTokens.swift:12`, `DesignTokensDark.swift:12`** — `public var` on properties of non-public class.

5. **`FontRegistration.swift:43`** — Emoji in log messages.

6. **`PrimerFont.swift:23`** — `struct` should be caseless `enum`.

7. **`PrimerFont.swift:132-145`** — Unused `tokens` parameter in `uiFontLargeIcon`/`uiFontSmallBadge`.

8. **`PrimerLayout.swift:11,43,71,91,106,113,122,130,137,150`** — Multiple namespace structs should be caseless enums.

9. **`AnimationConstants.swift:9`** — Same.

10. **`SlideInModifier.swift`, `AccessibilityConfigurable.swift`, `AccessibilityIdentifierProviding.swift`** — Empty files. Delete.

11. **`CheckoutColors.swift:69-98`** — Static methods that ignore `tokens` parameter.

12. **`DesignTokensManager.swift:54-55`** — Redundant doc comment.

### LOW

13. **`DesignTokensManager.swift:309-317`** — `loadJSON` swallows errors with `try?`.

---

## PR 08: Analytics, Logging & Accessibility (#1637)
**Files reviewed:** 31

### HIGH

1. **`AnalyticsEnvironment.swift:10` and many others** — ~10 types marked `public` but only used internally. Widens SDK surface unnecessarily.

2. **`DefaultAnalyticsInteractor.swift:18-22`** — Fire-and-forget `Task` inside actor: errors silently swallowed, ordering not guaranteed, `async` on `trackEvent` is misleading.

3. **`AnalyticsNetworkClient.swift:46-49`** — Silently sends request with nil body on encode failure.

4. **`LoggingSessionContext.swift:28`** — Singleton actor conflicts with testing (test pollution).

### MEDIUM

5. **`AnalyticsPayloadBuilder.swift:9`** — Stateless struct; methods could be static.

6. **`AnalyticsEnvironmentProvider.swift:9`** — Inconsistency: struct with instance methods vs `LogEnvironmentProvider` (enum with static methods).

7. **`SensitiveDataMasker.swift:41-42`** — `force_try` swiftlint disabled for regex.

8. **`AnalyticsEventMetadata.swift:13-18`** — `public` enum missing `Sendable`.

9. **`AnalyticsPayload.swift:11`** — Missing `Sendable` conformance (crosses actor boundaries).

10. **`AnalyticsSessionConfig.swift:11`** — Missing `Sendable`.

11. **`LoggingService.swift:147-150`** — Extension on `Error` is overly broad.

12. **`AccessibilityIdentifiers.swift:7`** — Some identifiers miss `{screen}` segment.

13. **`View+Accessibility.swift:42`** — `AnyView` type erasure harms SwiftUI performance.

14. **`AnalyticsEventBuffer.swift:11-13`** — Tuple typealias should be a struct.

15-19. Test naming conventions, test properties not `private`, inconsistent patterns.

### LOW

20-23. Minor factory method concerns, emoji in logs, print in test, missing test file.

---

## PR 09: Services & Navigation (#1638)
**Files reviewed:** 21

### HIGH

1. **`CheckoutSDKInitializer.swift:96-99`** — `cleanup()` fire-and-forget `Task` for `DIContainer.clearContainer()`. Re-init before clear completes causes race.

2. **`CheckoutSDKInitializer.swift:68-71`** — `analyticsInteractor` resolved with `try?`, silently swallowing DI failures.

3. **`ErrorMessageResolver.swift:169`** — Hardcoded English fallback `"Field"` bypasses localization.

### MEDIUM

4. **`CheckoutRoute.swift:10`** — `PresentationContext` is `public` in `Internal/Navigation/`.

5. **`CheckoutNavigator.swift:30-32`** — Redundant computed property wrapping stored property.

6. **`CheckoutComponentsStrings.swift:12`** — Redundant doc comment.

7. **`CheckoutComponentsStrings.swift:570-578`** — Duplicate localization key with `paymentAmountTitle`.

8. **`VaultManagerProtocol.swift:11-23`** — 4-space indentation (rest uses 2-space).

### LOW

9. **`CheckoutComponentsStrings.swift:679`** — `otpCodePlaceholder` reuses `otpLabel` key.

10. **`CheckoutComponentsStrings.swift:615`** — `cvvStandardPlaceholder` duplicates `cvvPlaceholder` key.

11. **`ErrorMessageResolver.swift:9`** — Should be caseless `enum` (all static methods).

---

## PR 10: Interactors & Bridge (#1639)
**Files reviewed:** 12

### HIGH

1. **`PrimerPaymentMethodType+ImageName.swift:20`** — Google Pay maps to `.appleIcon` for `defaultImageName`. Bug — shows Apple icon for Google Pay.

### MEDIUM

2. **`CheckoutComponentsPaymentMethodsBridge.swift:98-172`** — Code duplication with `HeadlessRepositoryImpl.swift:326-400`. `extractNetworkSurcharges`, `extractFromNetworksArray`, `extractFromNetworksDict`, `getRequiredInputElements` copy-pasted.

3. **`CheckoutComponentsPaymentMethodsBridge.swift:11`** — Bridge directly conforms to `GetPaymentMethodsInteractor` — blurs clean architecture boundary.

4. **`CheckoutComponentsPaymentMethodsBridge.swift`** — Excessive logging (~20 log calls in a data mapping function).

5. **`Tests/.../Mocks/MockHeadlessRepository.swift:11`** — `final class` (not actor) used in async tests. `SpyHeadlessRepository` correctly uses `actor` — this mock should too.

### LOW

6. **`CheckoutComponentsPaymentMethodsBridge.swift:10`** — Redundant doc comment.

7. **`PrimerPaymentMethodTypeImageNameTests.swift:41-43`** — Test documents wrong behavior as intentional.

---

## PR 11: Headless Repository (#1640)
**Files reviewed:** 15

### CRITICAL

1. **`HeadlessRepositoryImpl.swift:614-629`** — `selectCardNetwork` fires detached `Task` for `selectPaymentMethodIfNeeded` but doesn't await. `rawDataManager?.rawData = rawCardData` triggers synchronously. Race condition: payment may proceed before backend has network context. Comment says "CRITICAL for surcharge functionality."

### HIGH

2. **`HeadlessRepositoryImpl.swift:684-692`** — Vault payment timeout Task (60s) never cancelled on success. Wastes resources.

3. **`HeadlessRepositoryImpl.swift:52`** — `PaymentCompletionHandler` not `final`.

4. **`HeadlessRepositoryImpl.swift:15`** — `OneShotContinuation` is internal but only used in this file. Should be `private`.

5. **`HeadlessRepositoryImpl.swift:242`** — Redundant `@available(iOS 15.0, *)` on methods (class already has it). Same on lines 256, 263, 282, 858.

6. **`HeadlessRepositoryImpl.swift:252-253`** — Empty `catch` blocks silently swallow DI resolution failures.

7. **`HeadlessRepositoryImpl.swift:257-261`** — Double nil-check pattern (`ensureSettings` → `injectSettings` both check nil).

### MEDIUM

8. **`HeadlessRepositoryImpl.swift:588-594`** — Missing `nonisolated` on `getNetworkDetectionStream`/`getBinDataStream`.

9. **`HeadlessRepositoryImpl.swift:549-551`** — Manual payment handling silently ignored.

10. **`HeadlessRepositoryImpl.swift:289`** — Repository doesn't filter unsupported payment methods (bridge does).

11. **`HeadlessRepositoryImpl.swift:49`** — Redundant doc comment.

12-13. Duplicate test coverage, formatting pragmas.

### LOW

14. **`HeadlessRepositoryImpl.swift:828-830`** — `isLikelyURL` allocates array on every call.

15. Test naming inconsistency (camelCase vs snake_case).

---

## PR 12: Payment Methods (#1641)
**Files reviewed:** 30

### HIGH

1. **`QRCodePaymentMethod.swift:53-56`** — Direct instantiation of `ProcessQRCodePaymentInteractorImpl` bypasses DI container. Only method that does this.

2. **`WebRedirectPaymentMethod.swift:51`** — `repository` resolved with `try?` — nil repository silently passed to scope. Will crash on payment.

3. **`WebRedirectPaymentMethod.swift:80-88`** — `createScope` unconditionally throws `PrimerError.invalidArchitecture`. Dead code / code smell.

4. **`KlarnaRepositoryImpl.swift:146-155`** — Continuation timeout pattern fragile. Single missed `= nil` in future delegate would crash. Consolidate into reusable helper.

### MEDIUM

5. **`KlarnaRepositoryImpl.swift:21`, `AchRepositoryImpl.swift:32`** — Mixed DI patterns: some use `DependencyContainer.resolve()`, some use `PrimerSettings.current` directly.

6. **`FormRedirectPaymentMethod.swift`** — 4-space indentation (rest uses 2-space).

7. **`FormRedirectPaymentMethod.swift:64-84`** — `FormRedirectContainerView` defined in payment method file (one type per file rule).

8. **`FormRedirectPaymentMethod.swift:87-166`** — `BlikPaymentMethod` and `MBWayPaymentMethod` nearly identical. Consider shared factory.

9. **`PrimerPaymentMethodScope.swift:157,182,187`** — Emoji in log messages.

10. **`WebRedirectPaymentMethod.swift:14`** — Computed `var` for constant value. Use `let`.

11. **Repositories** — Inconsistent `ErrorHandler.handle` usage. WebRedirect/FormRedirect do it; ACH/Klarna/PayPal/QRCode don't.

12. **`ApplePayPaymentMethod.swift:14`** — Hardcoded `"APPLE_PAY"` instead of `PrimerPaymentMethodType.applePay.rawValue`.

13. **`FormRedirectPaymentMethod.swift:66`** — `@ObservedObject var scope` missing `private`.

### LOW

14. **All 8 methods** — Scope creation boilerplate duplicated (~16 lines each). Extract helper.

15. **`AchRepositoryImpl.swift:192`** — `UUID().uuidString` as fallback payment ID masks server issues.

16. **`WebRedirectRepositoryImpl.swift:47`** — Hardcoded `"WEB_REDIRECT"` in convenience init may be wrong for specific APMs.

17. **`KlarnaRepositoryImpl.swift:325-331`** — Same UUID fallback concern.

18. **All methods** — `content()` and `defaultContent()` always `fatalError`. Consider making protocol methods optional.

19. Test `@MainActor` placement inconsistency.

---

## PR 13: Presentation Scopes & Container (#1642)
**Files reviewed:** 19

### HIGH

1. **`DefaultCheckoutScope.swift:196`** — Hardcoded 500ms `Task.sleep` in `loadPaymentMethods()`. Artificial delay on every checkout init. Should only sleep when init screen is enabled.

2. **`DefaultCheckoutScope.swift:136-139`** — Unstructured `Task` in `init` with `[self]` capture. Race: `loadPaymentMethods()` may throw before `setupInteractors()` finishes.

3. **`DefaultCheckoutScope.swift:438-457`** — `navigationStateEquals` duplicates `Equatable` conformance on `NavigationState`. Will drift.

4. **`DefaultCardFormScope.swift:28`** — `public final class` in `Internal/` directory. Should be internal.

5. **`DefaultApplePayScope.swift:12`** — Same: `public final class` should be internal.

6. **`DefaultPayPalScope.swift:11`, `DefaultKlarnaScope.swift:11`, `DefaultAchScope.swift:12`, `DefaultWebRedirectScope.swift:11`, `DefaultFormRedirectScope.swift:11`, `DefaultQRCodeScope.swift:11`** — All `public final class` — should be internal.

7. **`DefaultCardFormScope.swift:9`** — `FieldValidationStates` is `public struct` in `Internal/`.

### MEDIUM

8. **`DefaultCheckoutScope.swift:511-513`** — Emoji in log message.

9. **`DefaultPaymentMethodSelectionScope.swift:113-118`** — Throws `NSError` instead of `PrimerError`/`ContainerError`.

10. **`DefaultWebRedirectScope.swift`** — 4-space indentation (rest uses 2-space).

11. **`DefaultFormRedirectScope.swift`** — Same.

12. **`DefaultCardFormScope+Validation.swift:21`** — `updateValidationState` exposes `FieldValidationStates` via `WritableKeyPath`.

13. **`DefaultSelectCountryScope.swift:14`** — Not `ObservableObject` unlike sibling scopes.

14. **`DefaultCheckoutScopeTests.swift:202-222`** — Tests manipulate local variables, not the actual SUT.

### LOW

15. **`ComposableContainer.swift:50-51`** — `safeRegister` swallows errors after logging.

16-17. Verbose doc comments.

---

## PR 14: UI Layer (#1643)
**Files reviewed:** 37

### HIGH

1. **`MockCardFormScope.swift:14`** — `public class` not `final`. Preview mocks should not be public.

2. **`MockDIContainer.swift:13`** — Same: `public final class` — preview utilities should not be public.

3. **`PaymentMethodComponents.swift:75`** — Downcasts `checkoutScope as? DefaultCheckoutScope` to access `checkoutNavigator`. Breaks scope abstraction.

### MEDIUM

4-6. **`CheckoutScopeObserver.swift:98,188,215`** — Emoji in log messages (3 locations).

7. **`SDKInitializationViews.swift:19`** — Hardcoded `spacing: 20` should use design tokens.

8. **`PaymentMethodButton.swift:22-71`** — Duplicated background/overlay inside and outside button label.

9. **`PayPalView.swift:116`** — Direct `UIImage(named:)` instead of `PrimerPaymentMethodType.defaultImageName.image`.

10. **`VaultedPaymentMethodCard.swift:98-99`** — Hardcoded font size and frame dimensions.

11. **`CardFormScreen.swift:304-307`** — Downcasts to `DefaultCardFormScope` to call `performSubmit()` bypassing public API.

12. **`CardFormFieldsView.swift` and `CardFormScreen.swift`** — Nearly identical `renderField` (~150 lines duplicated).

13. **`PrimerSwiftUIBridgeViewController.swift:56`** — Emoji in log messages (multiple).

14. **`RTLSupport.swift:12`** — `UIApplication.shared` accessed synchronously without `@MainActor`.

15. **`SecureTextField.swift:19`** — `text` getter always returns `"****"` — breaks accessibility/testing reads.

16-17. Various hardcoded values, redundant `Group`.

### LOW

18. **`PaymentMethodsSection.swift:73`** — Redundant `id:` parameter if type is `Identifiable`.

---

## PR 15: Entry Points & Debug App (#1644)
**Files reviewed:** 14

### HIGH

1. **`PrimerCheckoutPresenter.swift:69`** — `@objc public final class` — verify `@objc` intentional since most methods use Swift-only types.

2. **`PrimerCheckoutPresenter.swift:443-448`** — Two `delegate` properties: `PrimerCheckoutPresenter.delegate` (a `PrimerDelegate?`) vs `.shared.delegate` (a `PrimerCheckoutPresenterDelegate?`). Confusing for merchants.

3. **`PrimerCheckout.swift:98`** — `DIContainer.shared` used in body. Two `PrimerCheckout` views with different settings share same container — cross-contamination risk.

### MEDIUM

4. **`PrimerCheckoutPresenter.swift:90-92`** — `override private init()` unusual but correct.

5. **`PrimerCheckout.swift:76-91`** — Internal init accepts `diContainer` parameter but body ignores it.

6. **`CheckoutComponentsMenuViewController.swift:13-14`** — Implicitly unwrapped optionals on properties.

7-8. Missing availability annotations, inconsistent patterns.

### LOW

9. **`PrimerCheckoutPresenter.swift:232-253`** — Different dismiss timing behavior if controller missing.

10-11. Minor Debug App style issues.

---

## Cross-PR Patterns to Address

### 1. Public Access on Internal Types (HIGH priority, ~30 types)
Nearly every `Default*Scope`, DI framework type, analytics model, and validation type in `Internal/` directories is marked `public`. This should be a bulk fix: grep for `public` in `Internal/` paths and remove unless justified.

### 2. Missing `final` on Classes (MEDIUM priority, ~15 classes)
`WeakBox`, `SyncCache`, `ThreadSafeContainer`, `ContainerRegistrationBuilderImpl`, `PaymentCompletionHandler`, `MockCardFormScope`, test helper types.

### 3. Emoji in Log Messages (MEDIUM priority, ~25 locations)
Pervasive across: analytics services, logging services, navigation, scopes, bridge, UI observer. Grep for emoji characters in `.swift` files.

### 4. Namespace Structs → Caseless Enums (LOW priority, ~12 types)
`PrimerFont`, `PrimerSpacing`, `PrimerSize`, `PrimerRadius`, `PrimerComponentHeight`, `PrimerComponentWidth`, `PrimerIconSize`, `PrimerBorderWidth`, `PrimerScale`, `PrimerAnimationDuration`, `AnimationConstants`, `ErrorMessageResolver`, `ApplePayRequestBuilder`.

### 5. Inconsistent Error Handling (HIGH priority)
Three patterns in use: `handled(error:)`, `ErrorHandler.handle(error:)`, and silent `try?`. Should standardize.

### 6. Indentation Inconsistency (MEDIUM priority)
`FormRedirectPaymentMethod`, `DefaultWebRedirectScope`, `DefaultFormRedirectScope`, `VaultManagerProtocol` use 4-space; rest of codebase uses 2-space.
