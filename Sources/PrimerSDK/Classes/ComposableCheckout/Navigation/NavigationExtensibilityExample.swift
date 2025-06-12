import Foundation
import SwiftUI

// MARK: - Example: Extending Navigation System
// This file demonstrates how easy it is to extend the navigation system
// with new route types without modifying existing code (Open/Closed Principle)

@available(iOS 15.0, *)
enum OnboardingRoute: NavigationRoute {
    case welcome
    case features
    case permissions
    case complete

    var id: String {
        switch self {
        case .welcome: return "onboarding-welcome"
        case .features: return "onboarding-features"
        case .permissions: return "onboarding-permissions"
        case .complete: return "onboarding-complete"
        }
    }

    var routeName: String {
        switch self {
        case .welcome: return "Welcome Screen"
        case .features: return "Features Overview"
        case .permissions: return "Permissions Request"
        case .complete: return "Onboarding Complete"
        }
    }

    var navigationBehavior: NavigationBehavior {
        switch self {
        case .welcome:
            return .reset  // Start fresh
        case .features, .permissions:
            return .push   // Linear progression
        case .complete:
            return .replace // Replace final step
        }
    }

    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: OnboardingRoute, rhs: OnboardingRoute) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Example: Specialized Coordinator
@available(iOS 15.0, *)
@MainActor
class OnboardingCoordinator: NavigationCoordinator, LogReporter {
    typealias Route = OnboardingRoute

    @Published var navigationStack: [OnboardingRoute] = []

    var currentRoute: OnboardingRoute {
        navigationStack.last ?? .welcome
    }

    init() {
        // Start with welcome screen
        navigationStack = [.welcome]
    }

    func navigate(to route: OnboardingRoute) {
        // Custom onboarding logic - prevent going backwards
        if case .push = route.navigationBehavior,
           let currentIndex = OnboardingRoute.allCases.firstIndex(of: currentRoute),
           let targetIndex = OnboardingRoute.allCases.firstIndex(of: route),
           targetIndex < currentIndex {
            // Don't allow backward navigation in onboarding
            logger.debug(message: "🚫 Backward navigation blocked in onboarding")
            return
        }

        // Standard navigation behavior
        switch route.navigationBehavior {
        case .push:
            navigationStack.append(route)
        case .reset:
            navigationStack = [route]
        case .replace:
            if !navigationStack.isEmpty {
                navigationStack[navigationStack.count - 1] = route
            } else {
                navigationStack = [route]
            }
        }

        logger.debug(message: "📱 [OnboardingCoordinator] " + route.routeName)
    }

    func goBack() {
        // Custom behavior: onboarding doesn't allow going back
        logger.debug(message: "🚫 Back navigation disabled in onboarding")
    }

    func resetToRoot() {
        navigate(to: .welcome)
    }
}

// MARK: - Extension for CaseIterable (for the example above)
@available(iOS 15.0, *)
extension OnboardingRoute: CaseIterable {
    static let allCases: [OnboardingRoute] = [.welcome, .features, .permissions, .complete]
}

// MARK: - Example Usage Demonstration
@available(iOS 15.0, *)
@MainActor
struct NavigationUsageExample {

    /// Example 1: Using the generic factory
    static func createDifferentCoordinators() {
        // Create checkout coordinator
        let checkoutCoordinator = NavigationCoordinatorFactory.createCheckoutCoordinator()

        // Create generic coordinator (demonstrates protocol usage)
        let genericCoordinator = NavigationCoordinatorFactory.createCoordinator(for: CheckoutRoute.self)

        // Both conform to NavigationCoordinator protocol
        print("Checkout coordinator depth: \(checkoutCoordinator.navigationDepth)")
        print("Generic coordinator can go back: \(genericCoordinator.canGoBack)")
    }

    /// Example 2: Protocol-based navigation
    static func demonstrateProtocolUsage<T: NavigationCoordinator>(coordinator: T) {
        // This function works with ANY NavigationCoordinator implementation
        print("Current route: \(coordinator.currentRoute.id)")
        print("Navigation info: \(coordinator.navigationInfo)")

        // Can call methods defined in the protocol
        if coordinator.canGoBack {
            coordinator.goBack()
        }
    }

    /// Example 3: Easy extension for new features
    static func demonstrateExtensibility() {
        let onboardingCoordinator = OnboardingCoordinator()

        // Same protocol, different behavior
        demonstrateProtocolUsage(coordinator: onboardingCoordinator)

        // Onboarding-specific navigation
        onboardingCoordinator.navigate(to: .features)
        onboardingCoordinator.navigate(to: .permissions)
        onboardingCoordinator.navigate(to: .complete)
    }
}

// MARK: - Future Route Types (Examples)
// These demonstrate how easy it is to add new route types

@available(iOS 15.0, *)
enum SettingsRoute: NavigationRoute {
    case main
    case profile
    case preferences
    case about

    var id: String { "settings-\(self)" }
    var routeName: String { String(describing: self).capitalized }
    var navigationBehavior: NavigationBehavior { .push }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: SettingsRoute, rhs: SettingsRoute) -> Bool { lhs.id == rhs.id }
}

@available(iOS 15.0, *)
enum PaymentFlowRoute: NavigationRoute {
    case selectAmount
    case chooseMethod
    case enterDetails
    case confirm
    case processing
    case result

    var id: String { "payment-\(self)" }
    var routeName: String { String(describing: self).capitalized }
    var navigationBehavior: NavigationBehavior {
        self == .selectAmount ? .reset : .push
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: PaymentFlowRoute, rhs: PaymentFlowRoute) -> Bool { lhs.id == rhs.id }
}
