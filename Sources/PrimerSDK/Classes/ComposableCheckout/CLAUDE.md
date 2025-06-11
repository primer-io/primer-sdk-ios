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
- **PrimerCheckout.swift**: Main SwiftUI view for the checkout experience
- **PrimerCheckoutSheet.swift**: Bottom sheet presentation
- **PrimerCheckoutViewModel.swift**: Main view model managing checkout state
- **PrimerCheckoutScope.swift**: Dependency scope for checkout lifecycle

#### 2. Dependency Injection System
The module uses a custom async-first DI container:
- **Actor-based**: Thread-safe by design
- **Async/await**: Modern Swift concurrency
- **Three retention policies**: transient, singleton, weak
- **Circular dependency detection**: O(1) performance
- **SwiftUI integration**: Environment-based injection

#### 3. Payment Methods
Each payment method follows a consistent pattern:
- **PaymentMethodProtocol**: Common interface for all payment methods
- **Scope**: Dependency container for method-specific dependencies
- **ViewModel**: Business logic and state management
- **View**: SwiftUI presentation
- **Validators**: Input validation rules

Currently implemented:
- Card payments (we need to start using DI framework where needed)
- Apple Pay (todo)
- PayPal (todo)

#### 4. Validation System
Comprehensive input validation framework:
- **ValidationService**: Core validation engine
- **ValidationRule**: Protocol for validation rules
- **FormValidator**: Coordinates multiple field validations
- **Field-specific validators**: CVV, card number, expiry, etc.

## Usage Patterns

### Adding a New Payment Method

1. Create the payment method structure:
```
PaymentMethods/NewMethod/
├── NewMethodPaymentMethod.swift      # PaymentMethodProtocol implementation
├── NewMethodScope.swift             # DependencyScope implementation
├── NewMethodViewModel.swift         # Business logic
├── NewMethodView.swift             # SwiftUI view
└── Validation/                     # If needed
    └── NewMethodValidator.swift
```

2. Implement PaymentMethodProtocol:
```swift
@MainActor
final class NewMethodPaymentMethod: PaymentMethodProtocol {
    let id = "new_method"
    let name = "New Method"
    let icon = "newmethod.icon"
    
    func process() async throws -> PaymentResult {
        // Implementation
    }
    
    func createView() -> AnyView {
        AnyView(NewMethodView())
    }
}
```

3. Register in CompositionRoot:
```swift
_ = try? await container.register((any PaymentMethodProtocol).self)
    .named("new_method")
    .asTransient()
    .with { resolver in
        return await NewMethodPaymentMethod()
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

## Current Status

The ComposableCheckout module is under active development on the `bn/feature/stepByStepDI` branch. Key areas of ongoing work:
- Completing payment method implementations
- Enhancing the validation system
- Improving SwiftUI performance
- Adding more design tokens

When contributing, ensure your changes align with the established patterns and maintain the module's architectural integrity.