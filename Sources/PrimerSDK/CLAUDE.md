# PrimerSDK Core Module

This module contains the main SDK implementation with three integration approaches:

## Integration Approaches

### Drop-in Integration
Complete UI solution with minimal integration effort. Located in `Classes/Core/Primer/`.
- Entry point: `Primer.swift`
- Delegate: `PrimerDelegate`
- Full UI provided by SDK

### Headless Integration  
API-driven solution with complete UI control. Located in `Classes/Core/PrimerHeadlessUniversalCheckout/`.
- Entry point: `PrimerHeadlessUniversalCheckout.swift`
- No UI components provided
- `RawDataManager` for direct payment processing

### CheckoutComponents Integration
Modern SwiftUI scope-based solution with Android API parity. Located in `Classes/CheckoutComponents/`.
- Entry points: `CheckoutComponentsPrimer.swift` (UIKit bridge), `PrimerCheckout.swift` (SwiftUI)
- Scope-based architecture
- Full UI customization via closure properties
- Actor-based dependency injection

## Key Components

- **Payment Services**: Shared payment processing logic
- **Data Models**: Core business entities and API models  
- **Services**: Infrastructure layer (networking, parsing)
- **User Interface**: UIKit components for Drop-in
- **PCI**: Payment Card Industry compliant secure data handling
- **CheckoutComponents**: SwiftUI framework with production-ready scopes

## Platform Requirements

- iOS 13.1+ (Drop-in, Headless)
- iOS 15.0+ (CheckoutComponents)
- Swift 5.3+
- Xcode 13.0+