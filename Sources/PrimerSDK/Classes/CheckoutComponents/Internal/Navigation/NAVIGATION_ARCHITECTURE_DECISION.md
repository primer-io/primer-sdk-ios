# Navigation Architecture Decision Document - CheckoutComponents

## Overview

This document explains why CheckoutComponents uses a **state-driven navigation pattern** instead of traditional SwiftUI navigation approaches. This decision was made after evaluating multiple patterns for iOS 15+ SDK compatibility, performance, and maintainability.

## Problem Statement

**Requirements:**
- iOS 15+ compatibility (NavigationStack requires iOS 16+)
- SDK integration without host app conflicts
- Smooth animations and predictable behavior
- Testable and maintainable architecture
- Support for complex payment flows with 5+ screens
- **NO Combine usage** (per CheckoutComponents implementation plan)

## Evaluated Approaches

### ❌ Approach 1: Hidden NavigationLink Pattern

```swift
// REJECTED - Common but problematic pattern
struct HiddenLinkNavigation: View {
    @State private var path: [Route] = []
    
    var body: some View {
        NavigationView {
            ContentView()
                .background(
                    NavigationLink(
                        destination: destinationView,
                        isActive: .constant(!path.isEmpty),  // ⚠️ One-way binding
                        label: { EmptyView() }
                    )
                    .hidden()  // ⚠️ Always in memory
                )
        }
    }
}
```

**Problems:**
- ❌ **State Sync Issues**: `.constant()` binding can't be updated by NavigationLink
- ❌ **Memory Overhead**: Destination views always in memory
- ❌ **iOS 15 Bugs**: Unreliable back navigation behavior
- ❌ **Single Destination**: Can't handle navigation stacks properly
- ❌ **Host Conflicts**: Nested NavigationViews cause issues in SDK context

### ❌ Approach 2: Multiple NavigationLinks

```swift
// REJECTED - Scales poorly
struct MultiLinkNavigation: View {
    @State private var showPaymentMethods = false
    @State private var showCardForm = false
    @State private var showResult = false
    
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink("Payment Methods", isActive: $showPaymentMethods) {
                    PaymentMethodsView()
                }
                NavigationLink("Card Form", isActive: $showCardForm) {
                    CardFormView()
                }
                NavigationLink("Result", isActive: $showResult) {
                    ResultView()
                }
            }
        }
    }
}
```

**Problems:**
- ❌ **Exponential Complexity**: N screens = N state variables + N NavigationLinks
- ❌ **State Management**: Complex coordination between multiple boolean flags
- ❌ **Memory Waste**: All destinations always exist in view hierarchy
- ❌ **Navigation Logic**: Scattered across multiple components

### ❌ Approach 3: NavigationStack (iOS 16+ Only)

```swift
// REJECTED - iOS version limitation
@available(iOS 16.0, *)
struct NavigationStackApproach: View {
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            ContentView()
                .navigationDestination(for: Route.self) { route in
                    destinationView(for: route)
                }
        }
    }
}
```

**Problems:**
- ❌ **iOS 16+ Only**: Excludes significant user base (iOS 15 devices)
- ❌ **SDK Constraint**: Can't use latest APIs in SDK targeting older iOS

### ❌ Approach 4: Combine-based Navigation

```swift
// REJECTED - Violates CheckoutComponents architecture
import Combine  // ❌ Plan explicitly forbids Combine

class Navigator: ObservableObject {
    private let navigationSubject = PassthroughSubject<NavigationEvent, Never>()
    var navigationEvents: AnyPublisher<NavigationEvent, Never>
}
```

**Problems:**
- ❌ **Architecture Violation**: CheckoutComponents plan explicitly states "NO Combine imports"
- ❌ **Dependency Overhead**: Adds Combine framework dependency
- ❌ **AsyncStream Alternative**: AsyncStream provides same reactive functionality

## ✅ Chosen Approach: State-Driven Navigation with AsyncStream

### Architecture Overview

```swift
// CheckoutComponents implementation - Clean and predictable
@available(iOS 15.0, *)
struct PrimerCheckout: View {
    @StateObject private var coordinator: CheckoutCoordinator
    @Environment(\.designTokens) private var tokens
    
    var body: some View {
        VStack(spacing: 0) {
            currentScreen
        }
        .background(tokens?.primerColorBackground ?? .white)
        .environmentObject(coordinator)
    }
    
    @ViewBuilder
    private var currentScreen: some View {
        switch coordinator.currentRoute {
        case .splash:
            SplashScreen()
        case .loading:
            LoadingScreen()
        case .paymentMethodSelection:
            PaymentMethodSelectionScreen()
        case .cardForm:
            CardFormScreen()
        case .selectCountry:
            SelectCountryScreen()
        case .success(let result):
            SuccessScreen(result: result)
        case .error(let error):
            ErrorScreen(error: error)
        }
    }
}
```

### Core Components

#### 1. Route Definition - Type-Safe Navigation
```swift
enum CheckoutRoute: Hashable, Identifiable {
    case splash
    case loading
    case paymentMethodSelection
    case cardForm
    case selectCountry
    case success(CheckoutPaymentResult)
    case error(CheckoutPaymentError)
    
    var id: String {
        switch self {
        case .splash: return "splash"
        case .loading: return "loading"
        case .paymentMethodSelection: return "payment-method-selection"
        case .cardForm: return "card-form"
        case .selectCountry: return "select-country"
        case .success: return "success"
        case .error: return "error"
        }
    }
}
```

#### 2. Coordinator - Centralized Navigation Logic (NO Combine)
```swift
@MainActor
final class CheckoutCoordinator: ObservableObject, LogReporter {
    @Published var navigationStack: [CheckoutRoute] = []
    
    var currentRoute: CheckoutRoute {
        navigationStack.last ?? .splash
    }
    
    // AsyncStream for reactive navigation (NO Combine)
    var navigationEvents: AsyncStream<CheckoutRoute> {
        AsyncStream { continuation in
            // Implementation using AsyncStream instead of Combine
        }
    }
    
    func navigate(to route: CheckoutRoute) {
        switch route.navigationBehavior {
        case .push:
            navigationStack.append(route)
        case .reset:
            navigationStack = route == .splash ? [] : [route]
        case .replace:
            if !navigationStack.isEmpty {
                navigationStack[navigationStack.count - 1] = route
            } else {
                navigationStack = [route]
            }
        }
        logNavigation(to: route)
    }
    
    func goBack() {
        guard !navigationStack.isEmpty else { return }
        navigationStack.removeLast()
    }
    
    func handleCardFormSubmission() {
        navigate(to: .loading)
    }
    
    func handleCountrySelection() {
        navigate(to: .selectCountry)
    }
}
```

## Side-by-Side Comparison

| Feature | Hidden NavigationLink | Multiple NavigationLinks | NavigationStack | Combine Navigator | **Our State-Driven** |
|---------|----------------------|-------------------------|-----------------|-------------------|----------------------|
| **iOS Compatibility** | 15+ (buggy) | 15+ | 16+ only | 15+ | **15+ (reliable)** |
| **Memory Efficiency** | ❌ All views in memory | ❌ All views in memory | ✅ Lazy loading | ✅ Lazy loading | **✅ Only current view** |
| **State Management** | ❌ Complex sync | ❌ N boolean flags | ✅ Single path | ✅ Reactive | **✅ Single source of truth** |
| **Architecture Compliance** | ⚠️ Neutral | ⚠️ Neutral | ⚠️ Neutral | ❌ Violates plan | **✅ Follows plan** |
| **Dependencies** | ✅ SwiftUI only | ✅ SwiftUI only | ✅ SwiftUI only | ❌ Requires Combine | **✅ SwiftUI + AsyncStream** |
| **Testability** | ❌ Hard to mock | ❌ Multiple state vars | ✅ Good | ✅ Good | **✅ Excellent** |
| **SDK Integration** | ⚠️ Navigation conflicts | ⚠️ Navigation conflicts | ⚠️ Navigation conflicts | ⚠️ Navigation conflicts | **✅ Isolated** |
| **Performance** | ❌ Hidden view overhead | ❌ Multiple link overhead | ✅ Optimized | ✅ Optimized | **✅ Minimal overhead** |

## CheckoutComponents-Specific Benefits

### ✅ **Scope Integration**
```swift
// Perfect integration with scope-based architecture
final class DefaultCardFormScope: PrimerCardFormScope {
    private let coordinator: CheckoutCoordinator
    
    func navigateToCountrySelection() {
        coordinator.navigate(to: .selectCountry)
    }
    
    func onSubmit() {
        coordinator.navigate(to: .loading)
        // Process payment...
    }
}
```

### ✅ **AsyncStream State Management**
```swift
// Consistent with CheckoutComponents AsyncStream patterns
public var navigationState: AsyncStream<CheckoutRoute> {
    coordinator.navigationEvents
}

// Usage in scopes
for await route in navigationState {
    // React to navigation changes
}
```

### ✅ **No Architecture Violations**
- ✅ **NO Combine imports** (follows implementation plan)
- ✅ **AsyncStream for reactivity** (plan-compliant)
- ✅ **SwiftUI @Published** for UI updates
- ✅ **Exact Android API parity** maintained

## Code Examples: CheckoutComponents Navigation Flow

### Navigation Trigger (in Scope)
```swift
@MainActor
final class DefaultCardFormScope: PrimerCardFormScope {
    private let coordinator: CheckoutCoordinator
    
    func navigateToCountrySelection() {
        coordinator.navigate(to: .selectCountry)
    }
    
    func onSubmit() {
        coordinator.navigate(to: .loading)
        Task {
            do {
                let result = try await processPayment()
                coordinator.navigate(to: .success(result))
            } catch {
                coordinator.navigate(to: .error(error))
            }
        }
    }
}
```

### Integration with Existing Screens
```swift
// CardFormScreen.swift
struct CardFormScreen: View {
    @EnvironmentObject private var coordinator: CheckoutCoordinator
    
    var body: some View {
        // Screen content with navigation integration
        CardFormView()
            .onReceive(/* country selection events */) { country in
                // Handle country selection and navigate back
                coordinator.goBack()
            }
    }
}
```


## Why This Approach Wins for CheckoutComponents

### ✅ **Plan Compliance**
- **NO Combine**: Follows implementation plan's explicit requirement
- **AsyncStream**: Uses plan-approved reactive pattern
- **iOS 15+ Support**: Meets target platform requirements

### ✅ **Scope Integration**
- **Perfect Fit**: Navigation integrates seamlessly with scope-based architecture
- **Consistent API**: Matches Android navigation patterns
- **Type Safety**: Routes are strongly typed and validated

### ✅ **SDK-Appropriate Architecture**
- **Isolated Navigation**: No interference with host app's NavigationView
- **Modal Integration**: Works perfectly in CheckoutComponentsPrimer presentation
- **Clean Boundaries**: Clear separation between SDK and host navigation

## Conclusion

The state-driven navigation pattern with AsyncStream provides the best solution for CheckoutComponents by:
- **Following the implementation plan** (NO Combine requirement)
- **Maintaining iOS 15+ compatibility** 
- **Integrating perfectly with scope architecture**
- **Providing excellent performance** with lazy view creation
- **Ensuring testability** with mockable coordinator
- **Maintaining exact Android API parity**

This architecture decision ensures CheckoutComponents remains compliant with its implementation plan while providing a robust, maintainable navigation system.

---

*This document reflects the navigation architecture for CheckoutComponents and should be updated if navigation requirements change significantly.*