# CLAUDE.md - ComposableCheckout

This file provides guidance to Claude Code when working with the ComposableCheckout module of the Primer iOS SDK.

## Overview

ComposableCheckout is a modern, SwiftUI-based payment integration module designed for iOS 15+. It provides a component-based architecture that allows developers to compose payment experiences using reusable UI components and a powerful dependency injection system.

## Architecture

### Module Structure

```
ComposableCheckout/
├── Core/
│   ├── Concurrency/         # Async utilities
│   ├── DI/                  # Dependency Injection framework
│   ├── PrimerCheckout/      # Main checkout components
│   └── Validation/          # Input validation system
├── Design/                  # Design tokens and theming
├── Extensions/              # Swift extensions
├── PaymentMethods/          # Payment method implementations
└── UIKitSupport/           # UIKit integration examples
```

### Key Components

#### 1. PrimerCheckout (Entry Point)
- **PrimerCheckout.swift**: Main SwiftUI view with async container setup and error handling
- **PrimerCheckoutSheet.swift**: Bottom sheet presentation with navigation coordination
- **PrimerCheckoutViewModel.swift**: Central coordinator for checkout state and client token processing
- **PrimerCheckoutScope.swift**: Protocol interface for payment method access and selection

#### 2. Dependency Injection System
The module uses a custom async-first DI container:
- **Actor-based**: Thread-safe by design
- **Async/await**: Modern Swift concurrency
- **Three retention policies**: transient, singleton, weak
- **Circular dependency detection**: O(1) performance
- **SwiftUI integration**: Environment-based injection

#### 3. Payment Methods
Each payment method follows a scope-based pattern:
- **PaymentMethodProtocol**: Common interface with `ScopeType` associated type
- **Scope Protocol**: Payment method specific scope (e.g., `CardPaymentMethodScope`)
- **View Model**: Implements scope protocol, manages state and business logic
- **View**: SwiftUI presentation with `@ViewBuilder` customization support
- **Validators**: Input validation with comprehensive rule system

Currently implemented:
- **Card payments**: Complete implementation with CardPaymentMethod, CardViewModel, CardPaymentView
- **Payment Methods List**: PaymentMethodsListView with selection functionality
- **Apple Pay**: Structure exists, needs implementation
- **PayPal**: Structure exists, needs implementation

#### 4. Validation System
Comprehensive input validation framework:
- **ValidationService**: Core validation engine
- **ValidationRule**: Protocol for validation rules
- **FormValidator**: Coordinates multiple field validations
- **Field-specific validators**: CVV, card number, expiry, etc.

## Public API Design

### Scope-Based Architecture

The ComposableCheckout follows a scope-based pattern similar to Android Compose:

#### PrimerCheckoutScope
```swift
public protocol PrimerCheckoutScope {
    /// Reactive state stream for checkout state
    func state() -> AsyncStream<CheckoutState>
    
    /// AsyncStream of available payment methods
    func paymentMethods() -> AsyncStream<[any PaymentMethodProtocol]>
    
    /// AsyncStream of currently selected payment method
    func selectedPaymentMethod() -> AsyncStream<(any PaymentMethodProtocol)?>
    
    /// Updates the selected payment method
    func selectPaymentMethod(_ method: (any PaymentMethodProtocol)?) async
}
```

#### Payment Method Scope Pattern
```swift
public protocol PaymentMethodProtocol: Identifiable {
    associatedtype ScopeType: PrimerPaymentMethodScope
    
    var name: String? { get }
    var type: PaymentMethodType { get }
    var scope: ScopeType { get }
    
    /// Custom content with scope access
    func content<V: View>(@ViewBuilder content: @escaping (ScopeType) -> V) -> AnyView
    
    /// Default UI implementation
    func defaultContent() -> AnyView
}
```

#### Reactive State Management
All scopes use AsyncStream instead of Combine for state management:
```swift
public protocol CardFormScope: ObservableObject {
    /// Reactive state stream for card form
    func state() -> AsyncStream<CardFormState>
    
    // Update methods...
}
```

**Benefits of AsyncStream:**
- **No Combine Dependency**: Merchants don't need to import Combine
- **Modern Swift Concurrency**: Uses async/await patterns
- **Simple Integration**: Works seamlessly with SwiftUI's `.task` modifier
- **Consistent API**: All reactive streams use the same pattern

## Public API - ComposablePrimer

### New UIKit-Friendly API

ComposableCheckout now provides a `ComposablePrimer` class that follows the same pattern as the main SDK's `Primer` class:

```swift
// Simple presentation
ComposablePrimer.presentCheckout(with: clientToken)

// Present from specific view controller
ComposablePrimer.presentCheckout(with: clientToken, from: viewController)

// Present with custom content
ComposablePrimer.presentCheckout(with: clientToken, from: viewController) { scope in
    // Custom SwiftUI content
}

// Dismiss
ComposablePrimer.dismiss()

// Check state
if ComposablePrimer.isPresenting {
    // Checkout is currently being presented
}

// Reset state (for error recovery)
ComposablePrimer.resetPresentationState()
```

### Integration with Legacy SDK

The module now includes bridge services that connect to the existing SDK infrastructure:

- **LegacyConfigurationBridge**: Connects to PrimerAPIConfigurationModule for session setup
- **LegacyTokenizationBridge**: Maintains PCI compliance through existing TokenizationService
- **CheckoutNavigator**: Integrates with PrimerDelegateProxy for callbacks

## Usage Patterns

### Using ComposablePrimer (Recommended)

```swift
// In your view controller
ComposablePrimer.delegate = self
ComposablePrimer.presentCheckout(with: clientToken, from: self)

// Implement PrimerDelegate
extension ViewController: PrimerDelegate {
    func primerDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) {
        // Handle success
    }
    
    func primerDidFailWithError(_ error: Error, data: PrimerCheckoutData?, decisionHandler: @escaping (PrimerErrorDecision) -> Void) {
        // Handle error
        decisionHandler(.fail(withErrorMessage: error.localizedDescription))
    }
}
```

### Direct SwiftUI Integration

```swift
PrimerCheckout(clientToken: "your_token") { scope in
    // Access payment methods and selection state
    // Build custom UI using scope
}
```

### Adding a New Payment Method

1. Create the payment method structure following Card implementation pattern:
```
PaymentMethods/NewMethod/
├── NewMethodPaymentMethod.swift      # PaymentMethodProtocol implementation
├── NewMethodScope.swift             # Method-specific scope protocol
├── NewMethodViewModel.swift         # Scope implementation + business logic
├── NewMethodView.swift             # SwiftUI view
└── Validation/                     # If needed
    └── NewMethodValidator.swift
```

2. Implement PaymentMethodProtocol:
```swift
@available(iOS 15.0, *)
class NewMethodPaymentMethod: PaymentMethodProtocol {
    typealias ScopeType = NewMethodViewModel
    
    var id: String = UUID().uuidString
    var name: String? = "New Method"
    var type: PaymentMethodType = .newMethod
    
    @MainActor
    private let _scope: NewMethodViewModel
    
    @MainActor
    init() async throws {
        guard let container = await DIContainer.current else {
            throw ContainerError.containerUnavailable
        }
        self._scope = try await container.resolve(NewMethodViewModel.self)
    }
    
    @MainActor
    var scope: NewMethodViewModel { _scope }
    
    @MainActor
    func content<V: View>(@ViewBuilder content: @escaping (NewMethodViewModel) -> V) -> AnyView {
        AnyView(content(_scope))
    }
    
    @MainActor
    func defaultContent() -> AnyView {
        AnyView(NewMethodView(scope: _scope))
    }
}
```

3. Register in CompositionRoot:
```swift
_ = try await container.register(NewMethodViewModel.self)
    .asTransient()
    .with { resolver in
        // Resolve dependencies and create view model
    }
```

### Working with Validation

1. Create validation rules:
```swift
struct CustomRule: ValidationRule {
    let id = "custom"
    let errorMessage = "Invalid input"
    
    func validate(_ value: String) -> Bool {
        // Validation logic
    }
}
```

2. Use in validators:
```swift
class CustomValidator: BaseInputFieldValidator {
    override var rules: [ValidationRule] {
        [CustomRule()]
    }
}
```

### DI Container Usage

1. Register dependencies:
```swift
_ = try await container.register(MyService.self)
    .asSingleton()
    .with { resolver in
        MyServiceImpl(
            dependency: try await resolver.resolve(Dependency.self)
        )
    }
```

2. Resolve in ViewModels:
```swift
@MainActor
class MyViewModel: ObservableObject {
    init() async throws {
        guard let container = await DIContainer.current else {
            throw ContainerError.containerUnavailable
        }
        self.service = try await container.resolve(MyService.self)
    }
}
```

3. Use in SwiftUI:
```swift
struct MyView: View {
    @Environment(\.diContainer) private var container
    
    var body: some View {
        // Use container for dynamic resolution
    }
}
```

## Best Practices

### 1. Dependency Management
- Register all dependencies in CompositionRoot
- Use protocol registration for testability
- Prefer transient for ViewModels, singleton for services
- Handle resolution errors gracefully

### 2. Payment Method Development
- Follow the established pattern for consistency
- Implement proper error handling
- Use the validation framework for input fields
- Leverage the scope pattern for lifecycle management

### 3. SwiftUI Integration
- Use @MainActor for UI-related classes
- Leverage environment injection for container access
- Create reusable view components (like PrimerInputField)
- Follow SwiftUI best practices for state management

### 4. Testing
- Use mock containers for unit tests
- Test validators independently
- Mock payment services for integration tests
- Leverage the DI system for test doubles

## Common Tasks

### Running the Module
```swift
// Initialize the DI container
await CompositionRoot.configure()

// Create and present the checkout
let checkoutView = PrimerCheckout()
    .environment(\.diContainer, DIContainer.currentSync)
```

### Adding Design Tokens
1. Define tokens in DesignTokens.swift
2. Add dark mode variants in DesignTokensDark.swift
3. Register with DesignTokensKey
4. Access via DesignTokensManager

### Debugging DI Issues
```swift
// Get container diagnostics
let diagnostics = await container.getDiagnostics()
diagnostics.printDetailedReport()

// Check health
let health = await container.performHealthCheck()
health.printReport()
```

## Important Notes

- **iOS 15+ Required**: Uses modern Swift concurrency
- **SwiftUI Only**: No UIKit components in this module
- **Async-First**: Designed for async/await patterns
- **Type-Safe**: Leverages Swift's type system extensively
- **Testable**: DI enables easy mocking and testing

## Current Implementation Status

### Completed Features
- ✅ **Core Architecture**: DI container with actor-based thread safety
- ✅ **PrimerCheckout**: Main entry point with async setup and error handling
- ✅ **ComposablePrimer API**: UIKit-friendly wrapper following Primer.shared pattern
- ✅ **Scope-based API**: PaymentMethodProtocol with associated types
- ✅ **Card Payment**: Complete implementation with validation system
- ✅ **Payment Methods List**: Selection UI and view model
- ✅ **Validation Framework**: Rules-based validation with field-specific validators
- ✅ **Design Tokens**: Token management with dark mode support
- ✅ **Android API Alignment**: Complete scope-based architecture matching Android
- ✅ **Dynamic Field Visibility**: Fields shown/hidden based on backend configuration
- ✅ **GetRequiredFieldsInteractor**: Determines required fields dynamically
- ✅ **AsyncStream Migration**: All public APIs use AsyncStream instead of Combine
- ✅ **Legacy SDK Integration**: Bridge services for configuration and tokenization
- ✅ **Presentation State Management**: Robust handling of presentation lifecycle

### In Progress
- 🔄 **Navigation System**: CheckoutCoordinator and sheet presentation
- 🔄 **Error Handling**: Comprehensive error states and recovery
- 🔄 **Testing**: Unit tests for scope-based architecture

### Planned
- 📋 **Apple Pay**: Implementation following card payment pattern
- 📋 **PayPal**: Implementation following card payment pattern
- 📋 **More Payment Methods**: Following established scope pattern
- 📋 **Performance Optimization**: SwiftUI performance improvements

### Architecture Notes
- Current implementation uses async/await throughout
- DI container provides health checks and diagnostics
- Payment methods resolved lazily from container
- Scope pattern enables both default and custom UI implementations
- Validation system provides real-time field validation
- **Android-aligned architecture**: No static API, no wrappers, scope-only access
- **Dynamic configuration**: Field requirements determined by backend
- **AsyncStream for Reactive State**: All public APIs use AsyncStream instead of Combine
- **No External Dependencies**: Public API requires only SwiftUI, no Combine import needed

When contributing, ensure your changes align with the established scope-based patterns and maintain the module's architectural integrity.