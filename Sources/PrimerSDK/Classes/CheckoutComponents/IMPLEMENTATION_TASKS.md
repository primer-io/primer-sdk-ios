# CheckoutComponents Implementation Task List

## Overview
This file tracks the implementation progress of the CheckoutComponents framework. Each task corresponds to specific implementation work outlined in the IMPLEMENTATION_PLAN.md.

## Task Status Legend
- ⬜ Pending
- 🟦 In Progress  
- ✅ Completed

## Phase 1: Foundation & Public API
- ✅ Create directory structure under CheckoutComponents/
- ✅ Define PrimerCheckoutScope protocol with exact Android API match
- ✅ Define PrimerCardFormScope protocol with all 15 update methods
- ✅ Define PrimerPaymentMethodSelectionScope protocol
- ✅ Define PrimerSelectCountryScope protocol
- ✅ Create PrimerCheckout.swift main entry point matching Android
- ✅ Create initial CLAUDE.md documentation
- 🟦 Commit - feat: Add CheckoutComponents foundation and public API

## Phase 2: Core Infrastructure
- ✅ Copy DI framework from ComposableCheckout to Internal/DI/
- ✅ Copy Validation framework to Internal/Core/Validation/
- ✅ Copy Design tokens to Internal/Tokens/
- ✅ Copy Navigation system to Internal/Navigation/
- ✅ Create ComposableContainer with DI registrations
- ✅ Update all imports for new CheckoutComponents paths (no updates needed - framework is generic)
- 🟦 Commit - feat: Add core infrastructure (DI, validation, design tokens)

## Phase 3: Domain & Data Layers
- ✅ Create domain models (PrimerComposablePaymentMethod, PrimerInputElementType)
- ✅ Create GetPaymentMethodsInteractor
- ✅ Create ProcessCardPaymentInteractor with RawDataManager
- ✅ Create TokenizeCardInteractor
- ✅ Create ValidateInputInteractor
- ✅ Create HeadlessRepository protocol
- ✅ Create HeadlessRepositoryImpl with RawDataManager integration
- ✅ Create PaymentMethodMapper
- 🟦 Commit - feat: Add domain layer and data repositories

## Phase 4: Presentation Components
- ⬜ Copy and adapt CardNumberInput from ComposableCheckout
- ⬜ Copy and adapt CVVInput
- ⬜ Copy and adapt ExpiryDateInput
- ⬜ Copy and adapt CardholderNameInput
- ⬜ Convert billing address UIKit views to SwiftUI components
- ⬜ Create EmailInput and OTPCodeInput components
- ⬜ Create CardDetails composite component
- ⬜ Create BillingAddress composite with dynamic layout
- ⬜ Create InputConfigs wrapper for field configuration
- ⬜ Add co-badged cards network selector UI
- ⬜ Commit - feat: Add UI components and input fields

## Phase 5: Presentation Scopes & Screens
- ⬜ Implement DefaultCheckoutScope with AsyncStream state
- ⬜ Implement DefaultCardFormScope with RawDataManager and billing address
- ⬜ Implement DefaultPaymentMethodSelectionScope
- ⬜ Implement DefaultSelectCountryScope with search
- ⬜ Create all screens (Splash, Loading, Success, Error, CardForm, etc)
- ⬜ Setup CheckoutNavigator with state-driven navigation
- ⬜ Integrate 3DS handling via SafariViewController
- ⬜ Commit - feat: Implement scope classes and screens

## Phase 6: Integration
- ⬜ Add checkoutComponents case to CheckoutStyle enum
- ⬜ Update PrimerUIManager to support CheckoutComponents
- ⬜ Setup module initialization and DI container
- ⬜ Bridge PrimerSettings configuration
- ⬜ Commit - feat: Integrate CheckoutComponents with PrimerUIManager

## Phase 7: Documentation & Future Enhancements
- ⬜ Create README.md with usage examples
- ⬜ Add inline documentation for all public APIs
- ⬜ Add placeholders for future vaulting support
- ⬜ Commit - docs: Add documentation and usage examples

## Key Implementation Notes

### RawDataManager Integration
- Study how RawDataManager is created with paymentMethodType: "PAYMENT_CARD"
- Understand the delegate pattern and how to wrap it with async/await
- Pay attention to isUsedInDropIn parameter

### Co-Badged Cards
- Review screenshots at /Users/boris/Library/CloudStorage/Dropbox/Screenshots/Screenshot 2025-06-23 at 15.*.png
- Study currentlyAvailableCardNetworks property in CardFormPaymentMethodTokenizationViewModel
- Implement network selection dropdown UI

### Billing Address
- Billing address is NOT sent with tokenization
- It uses Client Session Actions API separately
- Field visibility is controlled by API configuration

## Progress Tracking
Last Updated: 2025-06-23
Current Phase: Phase 2 - Ready to commit
Next Action: Commit Phase 2 and start Phase 3 (Domain & Data Layers)

### Phase 1 Summary (Completed)
- Created complete directory structure
- Defined all 4 public scope protocols with exact Android API match
- Created PrimerCheckout.swift entry point
- Added comprehensive CLAUDE.md documentation
- All public APIs match Android exactly (methods, properties, nested scopes)

### Phase 2 Summary (Completed)
- Copied complete DI framework (actor-based, async/await)
- Copied validation framework with rules and validators
- Copied design tokens and manager
- Copied navigation system (CheckoutNavigator)
- Created simplified ComposableContainer for CheckoutComponents
- Removed CompositionRoot.swift (had too many non-existent dependencies)

### Phase 3 Summary
- Created domain models for payment methods and input types
- Implemented all interactors following SOLID principles
- Created HeadlessRepository abstraction for SDK integration
- Added PaymentMethodMapper for data transformation
- Implemented comprehensive validation rules for all 17 input types
- Updated DI container with all registrations