# Feature Specification: Bank Selector Scope for CheckoutComponents

**Feature Branch**: `003-bank-selector`
**Created**: 2026-02-09
**Status**: Draft
**Input**: User description: "Implement bank selector for checkout components, based on spike and existing Drop-In implementation"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Select a Bank and Complete Payment (Priority: P1)

A customer checking out with a bank-based payment method (e.g., iDEAL, Dotpay) is presented with a list of available banks. They browse or search the list, select their bank, and are redirected to the bank's authentication page to authorize the payment. After completing authorization, the customer is returned to the merchant app and sees a success confirmation.

**Why this priority**: This is the core end-to-end flow. Without bank selection and redirect, no bank-based payment can be completed. This delivers the fundamental value of the feature.

**Independent Test**: Can be fully tested by configuring a client session with ADYEN_IDEAL, launching CheckoutComponents, selecting a bank from the list, and verifying the redirect and payment completion flow.

**Acceptance Scenarios**:

1. **Given** a checkout session with iDEAL enabled, **When** the customer selects iDEAL as the payment method, **Then** a list of available banks is displayed.
2. **Given** the bank list is displayed, **When** the customer taps on a bank, **Then** the system immediately initiates tokenization with the selected bank and redirects the customer to the bank's authentication page (no confirmation step).
3. **Given** the customer has completed bank authentication, **When** they return to the app, **Then** the system polls for the payment result and displays a success or failure screen.
4. **Given** a checkout session with Dotpay enabled, **When** the customer selects Dotpay, **Then** the same bank selection flow works with Dotpay-specific banks.

---

### User Story 2 - Search and Filter Banks (Priority: P1)

A customer looking for their specific bank uses the search bar at the top of the bank list to quickly find it. As they type, the list filters in real-time to show only matching banks. The search is forgiving of accents and case differences.

**Why this priority**: Bank lists can be long (30+ banks for iDEAL). Without search, finding a specific bank is tedious and significantly degrades the user experience.

**Independent Test**: Can be tested by displaying the bank list and typing partial bank names, verifying real-time filtering with case-insensitive and diacritics-insensitive matching.

**Acceptance Scenarios**:

1. **Given** the bank list is displayed with a search bar, **When** the customer types a partial bank name, **Then** the list filters in real-time to show only banks whose name contains the search text.
2. **Given** the customer types "ing", **When** results are shown, **Then** banks like "ING Bank" appear regardless of case differences.
3. **Given** the customer types a query with no matching banks, **When** the list is empty, **Then** an appropriate empty state is displayed.
4. **Given** the customer clears the search text, **When** the search bar is empty, **Then** the full bank list is restored.

---

### User Story 3 - Merchant UI Customization (Priority: P2)

A merchant integrating the SDK wants to customize the appearance of the bank selector screen to match their brand. They configure visual properties such as the screen layout, bank item appearance, search bar styling, and empty state through the scope-based customization API, consistent with how other CheckoutComponents scopes support customization.

**Why this priority**: Customization is important for merchant adoption and brand consistency, but the feature is functional without it (default UI works out of the box).

**Independent Test**: Can be tested by passing customization configuration through the scope API and verifying the bank selector renders with the custom styles.

**Acceptance Scenarios**:

1. **Given** a merchant provides screen-level customization, **When** the bank selector is displayed, **Then** it renders with the merchant's custom layout.
2. **Given** a merchant provides bank item customization, **When** the bank list renders, **Then** each bank row reflects the custom appearance.
3. **Given** no customization is provided, **When** the bank selector is displayed, **Then** it renders with the default Primer-styled appearance.

---

### User Story 4 - Navigate Back or Cancel (Priority: P2)

A customer who opened the bank selector but wants to choose a different payment method can navigate back to the payment method selection screen. If the bank selector is the only available payment method (direct presentation), the customer can cancel the checkout entirely.

**Why this priority**: Navigation is essential for a complete user experience but is secondary to the core payment flow.

**Independent Test**: Can be tested by presenting the bank selector and verifying back/cancel navigation behavior in both multi-method and single-method checkout configurations.

**Acceptance Scenarios**:

1. **Given** the bank selector was opened from the payment method selection screen (multiple payment methods available), **When** the customer taps the back button, **Then** they return to the payment method selection screen.
2. **Given** the bank selector was opened directly (single payment method), **When** the customer taps the cancel button, **Then** the checkout is dismissed.
3. **Given** the customer is on the bank list, **When** they navigate back, **Then** no payment is initiated and no state is left behind.

---

### User Story 5 - Observe Bank Selector State (Priority: P2)

A merchant building a fully custom UI (not using default views) observes the bank selector state through an asynchronous stream. They receive state updates for loading, bank list readiness, and bank selection, allowing them to build their own bank selection interface. Post-selection processing, success, and failure are observed through the checkout scope's existing state.

**Why this priority**: State observation enables headless/custom UI usage, which is core to the CheckoutComponents value proposition but is used by fewer merchants than the default UI.

**Independent Test**: Can be tested by subscribing to the state stream and verifying that state transitions occur correctly: loading, ready (with banks), and selected.

**Acceptance Scenarios**:

1. **Given** a merchant observes the bank selector state stream, **When** the scope starts, **Then** state transitions from loading to ready with the bank list.
2. **Given** the state is ready, **When** the merchant calls `selectBank`, **Then** the state transitions to selected and the checkout scope takes over for processing/success/failure.
3. **Given** the scope starts, **When** the bank list fetch fails, **Then** the error is delegated to the checkout scope's standard error handling.

---

### Edge Cases

- What happens when the bank list API returns an empty list? The system displays a dedicated empty state view indicating no banks are available. Unlike the Drop-In UI (which shows a broken minimal UI), the CheckoutComponents bank selector explicitly handles this case.
- What happens when the bank list API call fails (network error, timeout)? The system delegates to the checkout scope's standard error screen with retry and "choose other payment method" options.
- What happens when the customer selects a bank that is marked as disabled? Disabled banks are visually distinguished and are not selectable.
- What happens when the customer switches away from the app during the redirect? Upon return, the system resumes polling for the payment status.
- What happens when polling times out after bank redirect? The system displays a failure state with an appropriate message.
- What happens when the search query contains special characters? The search handles special characters gracefully without crashing.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST fetch the list of available banks from the payment provider when the bank selector scope starts.
- **FR-002**: System MUST display each bank with its name and logo (when a logo URL is available from the provider).
- **FR-003**: System MUST provide a search bar that filters the bank list in real-time as the customer types.
- **FR-004**: Search filtering MUST be case-insensitive and diacritics-insensitive (e.g., "cafe" matches "Caf??").
- **FR-005**: System MUST initiate the payment tokenization flow when a customer selects a bank, passing the bank identifier to the tokenization request.
- **FR-006**: System MUST handle the web redirect flow after tokenization (redirect to bank auth page, return to app, poll for result).
- **FR-007**: System MUST expose the bank selector state as an asynchronous stream, emitting updates for: loading, ready (with banks), and selected. Processing, success, and failure states are handled by the parent checkout scope.
- **FR-008**: System MUST support both iDEAL (ADYEN_IDEAL) and Dotpay (ADYEN_DOTPAY) payment methods through a single reusable bank selector scope.
- **FR-009**: System MUST support navigation context: show a back button when presented from payment method selection, and a cancel button when presented directly.
- **FR-010**: System MUST display a loading state while the bank list is being fetched.
- **FR-011**: System MUST display an empty state when no banks match the search query.
- **FR-012**: System MUST delegate bank list fetch failures to the checkout scope's standard error screen, offering retry and "choose other payment method" options consistent with other payment method scopes.
- **FR-013**: System MUST allow merchants to customize the bank selector UI through scope-level component properties (screen, bank item, search bar, empty state).
- **FR-014**: System MUST register bank selector payment methods in the CheckoutComponents payment method registry so they appear in the payment method selection screen.
- **FR-015**: System MUST visually indicate disabled banks and prevent their selection.
- **FR-016**: System MUST delegate payment completion (success or failure) to the parent checkout scope for consistent result handling.
- **FR-017**: System MUST provide accessibility identifiers for all interactive elements following the `checkout_components_bank_selector_{element}` naming convention, with VoiceOver labels and hints for the search bar, bank items, loading state, empty state, and navigation buttons.
- **FR-018**: System MUST use localized strings for all user-facing text (screen title, search placeholder, empty state message, bank unavailable label, accessibility labels/hints) via `CheckoutComponentsStrings` with `NSLocalizedString`, supporting all 41 existing languages.
- **FR-019**: System MUST track analytics events for key user actions: `paymentMethodSelection` when the bank selector screen appears, `paymentSubmitted` when a bank is selected, and `paymentRedirectToThirdParty` when the web redirect begins — using the existing `CheckoutComponentsAnalyticsInteractorProtocol` fire-and-forget pattern.
- **FR-020**: System MUST display an empty state when the bank list API succeeds but returns zero banks, rather than showing a broken or minimal UI. This improves on the Drop-In behavior which has no explicit empty bank list handling.

### Key Entities

- **Bank**: Represents a selectable bank institution. Has an identifier, display name, optional logo URL, and a disabled flag indicating whether the bank is currently available for selection.
- **BankSelectorState**: Represents the current state of the bank selection flow. Includes the status (loading, ready, selected), the full bank list, filtered bank list, selected bank, and current search query. Processing, success, and failure states are managed by the parent checkout scope.
- **BankSelectorScope**: The public-facing scope that merchants interact with. Exposes the state stream, action methods (start, search, selectBank, cancel, onBack), and UI customization points.

## Clarifications

### Session 2026-02-09

- Q: Should selecting a bank immediately trigger the redirect, or should there be an intermediate confirmation? → A: Immediate redirect on bank tap (matches Drop-In and spike behavior).
- Q: On bank list fetch failure, should the bank selector handle it locally or delegate to the checkout scope's standard error screen? → A: Delegate to checkout scope's standard ErrorScreen with retry and "choose other payment method" options, consistent with all other payment method scopes.
- Q: Should the bank selector state include redirect/polling phases, or stop at "selected" and let the checkout scope handle the rest? → A: Scope state covers loading, ready, and selected only. Checkout scope handles processing, success, and failure navigation — consistent with Headless BanksStep/WebStep separation and CheckoutComponents patterns.

## Assumptions

- Only ADYEN_IDEAL and ADYEN_DOTPAY use the bank selector pattern. Other iDEAL variants (Buckaroo, Mollie, Pay.nl, Worldpay) use plain web redirect where bank selection happens on the provider's web page.
- The existing bank list API (`listAdyenBanks`) and tokenization infrastructure (including `BankSelectorSessionInfo` and web redirect/polling) will be reused via interactors that delegate to the core SDK, with no reimplementation needed.
- The bank selector scope follows the same architectural patterns as existing CheckoutComponents scopes (protocol + default implementation + DI registration + payment method registry).
- Bank logos are provided as URLs by the API and are loaded asynchronously; missing logos are handled gracefully with a fallback.
- The feature targets iOS 15.0+ consistent with CheckoutComponents platform requirements.
- The locale and platform fields in the tokenization request default to "en_US" and "IOS" respectively, matching the existing Drop-In behavior.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Customers can browse, search, select a bank, and complete a bank-based payment (iDEAL or Dotpay) end-to-end through CheckoutComponents without errors.
- **SC-002**: Bank list search returns filtered results within 100ms of user input, providing a responsive filtering experience.
- **SC-003**: The bank selector scope exposes a state stream (loading, ready, selected) that allows merchants to build fully custom bank selection UIs without relying on default views.
- **SC-004**: Merchants can customize the bank selector appearance (screen, bank items, search bar, empty state) using the same scope-based customization patterns as other CheckoutComponents scopes.
- **SC-005**: The feature maintains API parity with the equivalent Android CheckoutComponents bank selector implementation.
- **SC-006**: All bank selector state transitions (loading, ready, selected) are observable and occur in the correct sequence. Post-selection states (processing, success, failure) are handled by the checkout scope's existing navigation.
- **SC-007**: Bank selector screen is fully accessible via VoiceOver with appropriate labels, hints, and traits for all interactive elements.
- **SC-008**: All user-facing text is localized via CheckoutComponentsStrings, with English as the base language and entries for all 41 supported languages.
- **SC-009**: Key user actions (screen shown, bank selected, redirect) are tracked via the existing CC analytics infrastructure.
- **SC-010**: Minimum high-value test coverage exists for the interactor (bank mapping, payment execution), scope (state transitions, search filtering, disabled bank rejection), and state model (initialization, equality).
