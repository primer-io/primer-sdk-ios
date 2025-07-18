# CLAUDE.md - PCI Compliant Payment Processing

This directory contains PCI DSS (Payment Card Industry Data Security Standard) compliant components for secure payment data handling.

## Overview

The PCI module ensures that all sensitive payment data (card numbers, CVV, etc.) is handled securely throughout the SDK, following PCI DSS requirements for tokenization and data transmission.

## Architecture

### Secure Data Flow
```
User Input → PCI Components → Tokenization → Secure Transmission → Backend
```

**Key Principle**: Sensitive data never persists in memory longer than necessary and is immediately tokenized.

### Core Components

#### Checkout Components (`Checkout Components/`)
Secure data collection and processing:

**PrimerCardData.swift**:
- Secure card data container
- Automatic data sanitization
- Memory-safe string handling

**PrimerRawCardDataTokenizationBuilder.swift**:
- Converts raw card data to secure tokens
- Validates data integrity during transformation
- Handles card network detection

**PrimerOTPData.swift**:
- One-time password secure handling
- Temporary storage with automatic cleanup
- Integration with SMS/email verification flows

**PrimerPhoneNumberData.swift**:
- Phone number validation and formatting
- International format standardization
- Privacy-compliant storage

#### Tokenization Service (`TokenizationService.swift`)
Central tokenization engine:
- **Card Tokenization**: Convert card data to secure tokens
- **Batch Processing**: Handle multiple payment instruments
- **Error Recovery**: Robust error handling with retry logic
- **Analytics Integration**: Track tokenization success/failure rates

#### User Interface (`User Interface/`)
PCI-compliant input components:

**Security Features**:
- No screenshot capture for sensitive fields
- Automatic field clearing on app backgrounding
- Secure keyboard handling
- Paste protection for sensitive fields

**Text Fields**:
- `PrimerCardNumberFieldView`: Card number input with real-time validation
- `PrimerCVVFieldView`: CVV input with automatic masking
- `PrimerExpiryDateFieldView`: Expiry date with smart formatting
- `PrimerCardholderNameFieldView`: Name input with character filtering

### Services Architecture

#### Network Services (`Services/`)

**API Client (`API/Primer/`)**: 
- `PrimerAPI.swift`: PCI-specific API endpoints
- `PrimerAPIClient+PCI.swift`: Secure request/response handling
- Certificate pinning for API security
- Request/response encryption

**Network Infrastructure**:
- `RequestDispatcher.swift`: Secure request routing
- `RetryHandler.swift`: Intelligent retry with exponential backoff
- `NetworkReportingService.swift`: Security event logging

#### Data Processing
**JSON Handling**:
- `JSONLoader.swift`: Secure JSON parsing
- Memory-safe string processing
- Automatic sensitive data redaction in logs

**Network Factories**:
- `NetworkRequestFactory.swift`: Standardized secure request creation
- `NetworkResponseFactory.swift`: Response validation and parsing

### Tokenization View Models

#### Form-Based Tokenization (`FormsTokenizationViewModel/`)

**CardFormPaymentMethodTokenizationViewModel**:
- Orchestrates the entire card form tokenization flow
- Manages field validation and interdependencies
- Handles real-time user feedback

**Field Components** (`Fields/`):
Each field implements secure data handling:
- **CardNumberField**: Luhn validation, network detection, secure masking
- **CVVField**: Length validation based on card network
- **ExpiryDateField**: Date validation, format standardization
- **AddressField**: International address format support

#### Component Manager
**InternalCardComponentsManager**:
- Coordinates between UI components and tokenization services
- Manages component lifecycle and cleanup
- Handles secure data transfer between components

## Security Practices

### Data Handling
1. **Minimal Exposure**: Sensitive data exists in memory only during processing
2. **Automatic Cleanup**: All sensitive strings cleared after use
3. **No Persistence**: Sensitive data never written to disk or UserDefaults
4. **Secure Transmission**: All API calls use certificate pinning and encryption

### Input Validation
1. **Real-time Validation**: Immediate feedback on input validity
2. **Format Enforcement**: Automatic formatting for better UX and security
3. **Length Limits**: Prevent buffer overflow attempts
4. **Character Filtering**: Block potentially malicious input

### Memory Management
1. **Zero on Dealloc**: Sensitive memory regions cleared on deallocation
2. **Short Lifecycle**: Minimize time sensitive data exists in memory
3. **Secure Collections**: Use secure containers for sensitive data arrays
4. **Stack Allocation**: Prefer stack over heap for temporary sensitive data

## Usage Patterns

### Card Tokenization Flow
```swift
// 1. Collect card data securely
let cardData = PrimerCardData(
    cardNumber: secureCardNumber,
    cvv: secureCVV,
    expiryDate: expiryDate,
    cardholderName: cardholderName
)

// 2. Build tokenization request
let builder = PrimerRawCardDataTokenizationBuilder()
let tokenizationRequest = try builder.build(from: cardData)

// 3. Tokenize securely
let tokenizationService = TokenizationService()
let token = try await tokenizationService.tokenize(tokenizationRequest)

// 4. Clear sensitive data immediately
cardData.clear()
```

### Form Integration
```swift
// Create form with PCI-compliant fields
let formViewModel = CardFormPaymentMethodTokenizationViewModel()

// Add secure input fields
formViewModel.addField(CardNumberField())
formViewModel.addField(CVVField())
formViewModel.addField(ExpiryDateField())

// Handle tokenization
formViewModel.onTokenizationComplete = { token in
    // Process token (no sensitive data here)
    processPayment(with: token)
}
```

## Testing Strategy

### Security Testing
1. **Memory Analysis**: Verify sensitive data cleanup
2. **Network Testing**: Validate encryption and certificate pinning
3. **Input Fuzzing**: Test malicious input handling
4. **Screenshot Protection**: Verify sensitive fields are protected

### Unit Testing
1. **Mock Services**: Use secure mocks that don't expose real data
2. **Validation Testing**: Comprehensive input validation tests
3. **Error Scenarios**: Test error handling without data leakage
4. **Performance Testing**: Ensure security doesn't impact performance

## Compliance Notes

### PCI DSS Requirements
This module addresses the following PCI DSS requirements:
- **Requirement 3**: Protect stored cardholder data (via tokenization)
- **Requirement 4**: Encrypt transmission of cardholder data
- **Requirement 6**: Develop secure systems and applications
- **Requirement 8**: Identify and authenticate access to system components

### Audit Considerations
- All sensitive data handling is logged (without exposing data)
- Clear data lifecycle from input to tokenization
- Comprehensive error handling prevents data leakage
- Regular security reviews of tokenization flows

### Data Classification
- **Sensitive**: Card numbers, CVV, expiry dates
- **Personal**: Cardholder names, addresses
- **Public**: Payment method types, supported networks
- **Internal**: Tokenization metadata, validation results

## Best Practices

### For Developers
1. Never log sensitive payment data
2. Use provided secure components for all payment input
3. Clear sensitive variables immediately after use
4. Test thoroughly with both valid and invalid data
5. Follow the established tokenization patterns

### For Security Reviews
1. Verify no sensitive data in logs or crash reports
2. Confirm proper certificate pinning implementation
3. Review memory management for sensitive data
4. Validate input sanitization and validation
5. Check for secure data transmission protocols

### For Performance
1. Tokenization should complete within 2 seconds
2. UI responsiveness must be maintained during processing
3. Memory usage should be minimal and predictable
4. Network requests should have appropriate timeouts
5. Retry logic should not compromise security