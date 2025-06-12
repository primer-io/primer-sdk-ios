# Navigation Architecture Decision Document

## Overview

This document explains why ComposableCheckout uses a **state-driven navigation pattern** instead of traditional SwiftUI navigation approaches. This decision was made after evaluating multiple patterns for iOS 15+ SDK compatibility, performance, and maintainability.

## Problem Statement

**Requirements:**
- iOS 15+ compatibility (NavigationStack requires iOS 16+)
- SDK integration without host app conflicts
- Smooth animations and predictable behavior
- Testable and maintainable architecture
- Support for complex payment flows with 5+ screens

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
- ❌ **Migration Complexity**: Would require dual implementation

## ✅ Chosen Approach: State-Driven Navigation

### Architecture Overview

```swift
// Our implementation - Clean and predictable
@available(iOS 15.0, *)
struct PrimerCheckoutSheet: View {
    @StateObject private var coordinator: CheckoutCoordinator
    @Environment(\.designTokens) private var tokens
    
    var body: some View {
        VStack(spacing: 0) {
            currentScreen
        }
        .background(tokens?.primerColorBackground ?? .white)
        .environmentObject(coordinator)
        .animation(.easeInOut(duration: 0.4), value: coordinator.currentRoute.id)
    }
    
    @ViewBuilder
    private var currentScreen: some View {
        switch coordinator.currentRoute {
        case .splash:
            AsyncViewBuilder { try await SplashView.create(container: container) }
        case .paymentMethodsList:
            AsyncViewBuilder { try await PaymentMethodsListScreen.create(container: container) }
        case .paymentMethod(let method):
            AsyncViewBuilder { try await PaymentMethodScreen.create(paymentMethod: method, container: container) }
        case .success(let result):
            AsyncViewBuilder { try await ResultScreen.create(result: .success(result), container: container) }
        case .failure(let error):
            AsyncViewBuilder { try await ResultScreen.create(result: .failure(error), container: container) }
        }
    }
}
```

### Core Components

#### 1. Route Definition - Type-Safe Navigation
```swift
enum CheckoutRoute: Hashable, Identifiable, CaseIterable {
    case splash
    case paymentMethodsList
    case paymentMethod(PaymentMethodProtocol)
    case success(CheckoutPaymentResult)
    case failure(CheckoutPaymentError)
    
    var id: String {
        switch self {
        case .splash: return "splash"
        case .paymentMethodsList: return "payment-methods-list"
        case .paymentMethod(let method): return "payment-method-\(method.id)"
        case .success: return "success"
        case .failure: return "failure"
        }
    }
}
```

#### 2. Coordinator - Centralized Navigation Logic
```swift
@MainActor
final class CheckoutCoordinator: ObservableObject, LogReporter {
    @Published var navigationStack: [CheckoutRoute] = []
    @Published var currentRoute: CheckoutRoute = .splash
    
    func navigate(to route: CheckoutRoute) {
        switch route {
        case .splash:
            navigationStack = []
            currentRoute = .splash
        case .paymentMethodsList:
            navigationStack = [route]
            currentRoute = route
        case .paymentMethod, .success, .failure:
            navigationStack.append(route)
            currentRoute = route
        }
        logNavigation(to: route)
    }
    
    func goBack() {
        guard !navigationStack.isEmpty else { return }
        navigationStack.removeLast()
        updateCurrentRoute()
    }
    
    func handlePaymentMethodSelection(_ method: PaymentMethodProtocol) {
        navigate(to: .paymentMethod(method))
    }
}
```

#### 3. Async View Creation - Dependency Injection
```swift
private struct AsyncViewBuilder<Content: View>: View {
    @State private var content: Content?
    @State private var isLoading = true
    @State private var error: Error?
    private let asyncContent: () async throws -> Content
    
    var body: some View {
        Group {
            if let content = content {
                content
            } else if let error = error {
                ErrorView(error: error)
            } else if isLoading {
                ProgressView("Loading...")
            }
        }
        .task {
            do {
                content = try await asyncContent()
                isLoading = false
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
}
```

## Side-by-Side Comparison

| Feature | Hidden NavigationLink | Multiple NavigationLinks | NavigationStack | **Our State-Driven** |
|---------|----------------------|-------------------------|-----------------|----------------------|
| **iOS Compatibility** | 15+ (buggy) | 15+ | 16+ only | **15+ (reliable)** |
| **Memory Efficiency** | ❌ All views in memory | ❌ All views in memory | ✅ Lazy loading | **✅ Only current view** |
| **State Management** | ❌ Complex sync | ❌ N boolean flags | ✅ Single path | **✅ Single source of truth** |
| **Testability** | ❌ Hard to mock | ❌ Multiple state vars | ✅ Good | **✅ Excellent** |
| **SDK Integration** | ⚠️ Navigation conflicts | ⚠️ Navigation conflicts | ⚠️ Navigation conflicts | **✅ Isolated** |
| **Custom Animations** | ❌ Limited control | ❌ Limited control | ✅ Good control | **✅ Full control** |
| **Performance** | ❌ Hidden view overhead | ❌ Multiple link overhead | ✅ Optimized | **✅ Minimal overhead** |
| **Debugging** | ❌ Hard to debug | ❌ Complex state | ✅ Clear path | **✅ Clear state flow** |
| **Maintainability** | ❌ Fragile | ❌ Scales poorly | ✅ Good | **✅ Excellent** |

## Code Examples: Navigation Flow

### Navigation Trigger (in ViewModel)
```swift
@MainActor
final class PaymentMethodsListScreenViewModel: ObservableObject {
    private let coordinator: CheckoutCoordinator
    
    func handlePaymentMethodSelection(_ displayModel: PaymentMethodDisplayModel) {
        let method = findMatchingPaymentMethod(for: displayModel)
        if let method = method {
            coordinator.handlePaymentMethodSelection(method)  // Triggers navigation
        }
    }
}
```

### Animation Configuration
```swift
// Smooth transitions between screens
.animation(.easeInOut(duration: 0.4), value: coordinator.currentRoute.id)

// Custom transitions per screen
.transition(.asymmetric(
    insertion: .move(edge: .trailing),    // Slide in from right
    removal: .move(edge: .leading)        // Slide out to left
))
```

### Dependency Injection Integration
```swift
// Each screen resolves dependencies asynchronously
static func create(container: ContainerProtocol) async throws -> PaymentMethodsListScreen {
    let viewModel = try await PaymentMethodsListScreenViewModel.create(container: container)
    return PaymentMethodsListScreen(viewModel: viewModel)
}
```

## Why This Approach Wins

### ✅ **Predictable Behavior**
- **Single Source of Truth**: `coordinator.currentRoute` drives entire UI
- **Explicit State**: No hidden SwiftUI navigation state to get out of sync
- **Deterministic**: Same state always produces same UI

### ✅ **Excellent Performance**
```swift
// Only current screen exists in memory
switch coordinator.currentRoute {
case .paymentMethodsList:
    PaymentMethodsListScreen()  // ← Only this view is created
// Other cases not instantiated
}
```

### ✅ **SDK-Appropriate Architecture**
- **Isolated Navigation**: No interference with host app's NavigationView
- **Modal Integration**: Works perfectly in sheets/full-screen covers
- **Clean Boundaries**: Clear separation between SDK and host navigation

### ✅ **Highly Testable**
```swift
func testNavigationFlow() {
    let coordinator = CheckoutCoordinator(container: mockContainer)
    
    // Test navigation
    coordinator.navigate(to: .paymentMethodsList)
    XCTAssertEqual(coordinator.currentRoute, .paymentMethodsList)
    
    // Test back navigation
    coordinator.goBack()
    XCTAssertEqual(coordinator.currentRoute, .splash)
}
```

### ✅ **Future-Proof**
- **Migration Ready**: Easy to adopt NavigationStack when iOS 16+ becomes minimum
- **Extensible**: Adding new screens requires only updating the enum and switch
- **Maintainable**: Navigation logic centralized in coordinator

## Common Concerns Addressed

### "Why Not Use NavigationStack?"
**Answer**: iOS 15 support is critical for SDK adoption. 40%+ of users are still on iOS 15/16.

### "Hidden NavigationLink Works in My App"
**Answer**: It works until it doesn't. iOS 15 has documented issues with programmatic NavigationLink control. SDK code needs higher reliability standards.

### "This Seems Like More Code"
**Answer**: Initial setup is slightly more, but scales much better. Compare 5 screens:

```swift
// Hidden NavigationLink approach: 5 NavigationLinks + complex state sync
// Our approach: 1 coordinator + 5 enum cases + clean switch statement
```

### "What About Native Back Gestures?"
**Answer**: We implement custom back navigation through coordinator. For SDK use, this provides better control and consistent behavior across iOS versions.

## Migration Guide (If Needed)

### From Hidden NavigationLink
```swift
// Old approach
@State private var showPaymentForm = false
NavigationLink("", isActive: $showPaymentForm) { PaymentFormView() }.hidden()

// New approach  
coordinator.navigate(to: .paymentMethod(selectedMethod))
```

### From Multiple NavigationLinks
```swift
// Old approach
@State private var showScreen1 = false
@State private var showScreen2 = false
@State private var showScreen3 = false

// New approach
coordinator.currentRoute  // Single source of truth
```

## Conclusion

The state-driven navigation pattern provides the best balance of:
- **Reliability** on iOS 15+
- **Performance** with lazy view creation
- **Maintainability** with centralized logic
- **SDK Integration** without host conflicts
- **Testability** with mockable coordinator

This architecture decision prioritizes long-term maintainability and user experience over short-term implementation convenience. The pattern scales excellently as we add more screens and provides a solid foundation for the ComposableCheckout SDK.

---

*This document should be updated if navigation requirements change significantly or when iOS 16+ becomes the minimum supported version.*