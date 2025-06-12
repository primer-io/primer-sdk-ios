import SwiftUI
import Combine

@available(iOS 15.0, *)
@MainActor
final class CheckoutCoordinator: ObservableObject, LogReporter {
    // MARK: - Published Properties
    @Published var navigationStack: [CheckoutRoute] = []
    @Published var currentRoute: CheckoutRoute = .splash
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private let container: ContainerProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(container: ContainerProtocol) {
        self.container = container
        setupNavigationObservation()
    }

    // MARK: - Navigation Methods
    func navigate(to route: CheckoutRoute) {
        switch route {
        case .splash:
            // Reset to splash
            navigationStack = []
            currentRoute = .splash
        case .paymentMethodsList:
            if navigationStack.isEmpty {
                navigationStack = [route]
            } else {
                resetToRoot()
                navigationStack = [route]
            }
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

    func resetToRoot() {
        navigationStack = []
        currentRoute = .splash
    }

    func handlePaymentMethodSelection(_ method: any PaymentMethodProtocol) {
        navigate(to: .paymentMethod(method))
    }

    func handlePaymentSuccess(_ result: CheckoutPaymentResult) {
        navigate(to: .success(result))
    }

    func handlePaymentFailure(_ error: CheckoutPaymentError) {
        navigate(to: .failure(error))
    }

    // MARK: - Private Methods
    private func setupNavigationObservation() {
        $navigationStack
            .sink { [weak self] _ in
                self?.updateCurrentRoute()
            }
            .store(in: &cancellables)
    }

    private func updateCurrentRoute() {
        // Update currentRoute based on navigationStack
        if let lastRoute = navigationStack.last {
            currentRoute = lastRoute
        } else {
            currentRoute = .splash
        }
    }

    private func logNavigation(to route: CheckoutRoute) {
        logger.debug(message: "🧭 [CheckoutCoordinator] Navigating to: \(route.id)")
    }
}

// MARK: - DI Integration
@available(iOS 15.0, *)
extension CheckoutCoordinator {
    static func create(container: ContainerProtocol) async throws -> CheckoutCoordinator {
        return CheckoutCoordinator(container: container)
    }
}
