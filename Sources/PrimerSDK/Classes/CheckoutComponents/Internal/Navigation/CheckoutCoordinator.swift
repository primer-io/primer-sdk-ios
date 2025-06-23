//
//  CheckoutCoordinator.swift
//  PrimerSDK - CheckoutComponents
//
//  Navigation coordinator for CheckoutComponents using state-driven navigation
//  Adapted from ComposableCheckout, updated to remove Combine and follow AsyncStream patterns
//

import SwiftUI

// MARK: - Navigation Coordinator Protocol
@available(iOS 15.0, *)
@MainActor
protocol NavigationCoordinator: ObservableObject {
    associatedtype Route: NavigationRoute

    var navigationStack: [Route] { get set }
    var currentRoute: Route { get }

    func navigate(to route: Route)
    func goBack()
    func resetToRoot()
    func dismiss()
}

// MARK: - Checkout Navigation Coordinator
@available(iOS 15.0, *)
@MainActor
internal final class CheckoutCoordinator: NavigationCoordinator, LogReporter {
    typealias Route = CheckoutRoute

    // MARK: - Published Properties
    @Published var navigationStack: [CheckoutRoute] = []

    // MARK: - Computed Properties
    var currentRoute: CheckoutRoute {
        navigationStack.last ?? .splash
    }

    // MARK: - Initialization
    init() {
        logEvent("navigation_coordinator_initialized")
    }

    // MARK: - Navigation Methods
    func navigate(to route: CheckoutRoute) {
        // Performance optimization: avoid redundant navigation to same route
        if currentRoute == route {
            logEvent("navigation_redundant_attempt", parameters: route.analyticsParameters)
            return
        }

        let previousRoute = currentRoute

        // Use route's navigation behavior for consistent, optimized navigation
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

        // Enhanced logging with analytics
        logNavigation(from: previousRoute, to: route)
    }

    func goBack() {
        guard !navigationStack.isEmpty else { return }
        navigationStack.removeLast()
    }

    func resetToRoot() {
        navigationStack = []
    }
    
    func dismiss() {
        // Clear navigation stack and trigger dismissal
        navigationStack = []
        logEvent("navigation_dismissed")
        
        // The actual dismissal will be handled by the presenting view controller
        // This just signals the intent to dismiss
    }

    func handlePaymentMethodSelection(_ methodType: String) {
        navigate(to: .paymentMethod(methodType))
    }

    func handlePaymentSuccess(_ result: CheckoutPaymentResult) {
        navigate(to: .success(result))
    }

    func handlePaymentFailure(_ error: CheckoutPaymentError) {
        navigate(to: .failure(error))
    }

    // MARK: - Private Methods
    private func logNavigation(from previousRoute: CheckoutRoute, to route: CheckoutRoute) {
        // Enhanced analytics logging
        var parameters = route.analyticsParameters
        parameters["previous_route_id"] = previousRoute.id
        parameters["previous_route_name"] = previousRoute.routeName
        parameters["navigation_behavior"] = String(describing: route.navigationBehavior)

        logEvent("navigation_transition", parameters: parameters)

        // Performance optimization: avoid string interpolation unless debug logging is enabled
        logger.debug(message: "🧭 [CheckoutCoordinator] " + previousRoute.routeName + " → " + route.routeName)
    }

    private func logEvent(_ eventName: String, parameters: [String: Any] = [:]) {
        // This would integrate with your analytics service
        logger.debug(message: "📊 [Analytics] \(eventName): \(parameters)")
    }
}

// MARK: - DI Integration
@available(iOS 15.0, *)
extension CheckoutCoordinator {
    static func create(container: ContainerProtocol) async throws -> CheckoutCoordinator {
        return CheckoutCoordinator()
    }
}
