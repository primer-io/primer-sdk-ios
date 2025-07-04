# CLAUDE.md - Data Models

This directory contains the core data models and domain objects that represent the business entities throughout the Primer iOS SDK.

## Overview

The Data Models directory provides the foundational data structures used across all SDK integrations (Drop-in, Headless, and CheckoutComponents). These models ensure type safety, data integrity, and consistent API contracts.

## Architecture

### Model Categories

#### API Models (`API/`)
Network request and response models for communication with Primer's backend:

**Core API Models**:
- `Request.swift`: Base request structure and common request types
- `Response.swift`: Base response structure and common response types
- `ClientSessionAPIModel.swift`: Client session management
- `PaymentAPIModel.swift`: Payment processing requests/responses
- `VaultedPaymentMethods.swift`: Stored payment method operations

#### Payment Method Models
Domain-specific payment method representations:

**Card Payments**:
- `CardNetwork.swift`: Supported card networks (Visa, Mastercard, etc.)
- `CardButtonViewModel.swift`: Card payment button configuration

**Alternative Payment Methods**:
- `ApplePay.swift`: Apple Pay configuration and metadata
- `PayPal.swift`: PayPal-specific data structures
- `Klarna.swift`: Klarna Buy-Now-Pay-Later models
- `StripeAch.swift`: ACH bank transfer models
- `AdyenDotPay.swift`: Adyen payment method models

**Regional Payment Methods**:
- `RetailOutletsRetail.swift`: Retail outlet payment data
- `XenditRetailOutlets.swift`: Xendit retail payment models

#### Configuration Models
SDK and payment configuration:

**Core Configuration**:
- `PrimerConfiguration.swift`: Main SDK configuration
- `PrimerSettings.swift`: User-configurable SDK settings
- `PaymentMethodConfigurationOptions.swift`: Payment method specific settings

**Session Management**:
- `ClientSession.swift`: Active payment session data
- `ClientToken.swift`: Authentication and authorization tokens

#### Business Domain Models

**Currency Support** (`Currency/`):
- `Currency.swift`: Multi-currency representation and formatting
- `CurrencyLoader.swift`: Dynamic currency data loading
- `CurrencyStorageProtocol.swift`: Currency data persistence interface
- `CurrencyNetworkServiceProtocol.swift`: Currency API interface

**Geographic Data**:
- `CountryCode.swift`: ISO country code representations
- Address field models in various payment method implementations

**Transaction Data**:
- `PaymentResponse.swift`: Payment processing results
- `TokenizationResponse.swift`: Token creation results
- `TokenizationRequestBody.swift`: Token creation requests

### Specialized Model Groups

#### Theme and UI (`Theme/`)
UI customization and theming models:

**Public Theme API** (`Public/`):
- `PrimerThemeData.swift`: Main theming configuration
- `PrimerThemeData+Deprecated.swift`: Legacy theme support

**Internal Theme Implementation** (`Internal/`):
- `PrimerTheme+Colors.swift`: Color system
- `PrimerTheme+Typography.swift`: Font and text styling
- `PrimerTheme+Buttons.swift`: Button appearance
- `PrimerTheme+Inputs.swift`: Input field styling
- `PrimerTheme+Views.swift`: General view styling
- `PrimerTheme+Borders.swift`: Border and corner styling

**Core Theme Types**:
- `PrimerTheme.swift`: Main theme container
- `PrimerColor.swift`: Color representation and utilities
- `PrimerTheme+Images.swift`: Image and icon theming

#### PCI Compliance (`PCI/`)
Secure payment data handling models:
- `FormType.swift`: Different form types for secure data collection

#### Additional Info Models
Enhanced payment method data:
- `PrimerCheckoutAdditionalInfo.swift`: Extra checkout metadata
- `PrimerCheckoutQRCodeInfo.swift`: QR code payment data
- `PrimerCheckoutVoucherAdditionalInfo.swift`: Voucher payment details
- `PrimerMultibancoCheckoutAdditionalInfo.swift`: Multibanco-specific data

### Utility and Infrastructure Models

#### Error Handling
- `Throwable.swift`: Error type definitions and handling utilities

#### Data Processing
- `UniversalCheckoutViewModel.swift`: Universal checkout state management
- `VoucherValue.swift`: Voucher and discount representations

#### Integration Models
- `PrimerFlowEnums.swift`: Flow state and transition enums
- `PrimerSDKIntegrationType.swift`: Integration type identification
- `PrimerIntegrationOptions.swift`: Integration configuration options
- `PrimerInitializationData.swift`: SDK initialization parameters

#### Metadata Models
- `ImageName.swift`: Image asset naming and management
- `Notification.swift`: SDK notification system
- `Bin.swift`: Bank Identification Number data

### Payment Method Specific Models

#### Vault Management
- `PrimerVaultedPaymentMethodAdditionalData.swift`: Stored payment method metadata
- `PrimerVaultedCardAdditionalData.swift`: Stored card specific data

#### Request/Response Models
- `TokenizationRequestPaymentInstrument.swift`: Payment instrument definitions
- `TokenizationRequestPaymentSessionInfo.swift`: Session context for tokenization

#### Localization
- `PrimerLocaleData.swift`: Multi-language and region support

## Data Flow Patterns

### Request/Response Flow
```
Client → Request Model → API Client → Network → Server
Server → Network → Response Model → Business Logic → UI
```

### Configuration Flow
```
SDK Initialization → Configuration Models → Service Registration → Feature Enablement
```

### Payment Flow
```
User Input → Payment Method Model → Tokenization Request → Token Response → Payment Processing
```

## Usage Patterns

### Model Creation
```swift
// Create configuration
var configuration = PrimerConfiguration()
configuration.checkoutModules = [.paymentMethods]

// Create payment method
let cardNetwork = CardNetwork.visa
let paymentMethod = PrimerPaymentMethod(
    type: .adyenCard,
    name: "Credit Card",
    surcharge: nil
)
```

### API Integration
```swift
// Create API request
let request = PaymentAPIModel.CreatePaymentRequest(
    amount: 1000,
    currencyCode: "USD",
    paymentMethodData: paymentMethodData
)

// Handle API response
let response: PaymentAPIModel.CreatePaymentResponse = try await apiClient.createPayment(request)
```

### Theme Configuration
```swift
// Configure theme
var theme = PrimerTheme()
theme.colors.primary = PrimerColor(light: .systemBlue, dark: .systemIndigo)
theme.typography.body = .systemFont(ofSize: 16)

Primer.setTheme(theme)
```

## Validation and Type Safety

### Input Validation
Models include built-in validation for critical fields:
- Currency codes validated against ISO 4217
- Country codes validated against ISO 3166
- Card networks validated against supported types
- Amounts validated for positive values and currency precision

### Type Safety Features
- Strong typing for all enum values
- Optional vs required field distinction
- Codable conformance for API serialization
- Custom validation methods for complex business rules

## Testing Strategy

### Model Testing
1. **Serialization Tests**: Verify Codable conformance
2. **Validation Tests**: Test business rule validation
3. **Equality Tests**: Verify model comparison logic
4. **Performance Tests**: Large data set handling

### API Model Testing
1. **Request/Response Mapping**: Verify API contract compliance
2. **Error Handling**: Test malformed data scenarios
3. **Backward Compatibility**: Ensure API version compatibility
4. **Schema Validation**: Validate against API schema

## Best Practices

### Model Design
1. **Immutability**: Prefer immutable models where possible
2. **Value Types**: Use structs for data containers
3. **Minimal Dependencies**: Models should not depend on UI or services
4. **Clear Naming**: Self-documenting property and type names

### API Models
1. **Version Compatibility**: Support multiple API versions
2. **Optional Handling**: Graceful handling of missing fields
3. **Error Propagation**: Clear error messages for validation failures
4. **Documentation**: Comprehensive inline documentation

### Performance
1. **Lazy Loading**: Large models should support lazy property loading
2. **Memory Efficiency**: Minimize memory footprint for large collections
3. **Serialization Speed**: Optimize for fast JSON encoding/decoding
4. **Caching**: Support for model-level caching where appropriate

## Migration Strategy

### API Changes
- Maintain backward compatibility for existing models
- Introduce new models alongside legacy versions
- Provide migration utilities for data transformation
- Clear deprecation timeline for obsolete models

### Schema Evolution
- Support additive changes (new optional fields)
- Handle breaking changes with version-specific models
- Provide data migration tools for major changes
- Maintain comprehensive change documentation

This data model architecture provides a solid foundation for type-safe, maintainable, and scalable payment processing while supporting the diverse needs of different integration approaches.