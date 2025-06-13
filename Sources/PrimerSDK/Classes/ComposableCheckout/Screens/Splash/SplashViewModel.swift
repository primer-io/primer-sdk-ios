import Foundation
import Combine
import SwiftUI

@available(iOS 15.0, *)
@MainActor
final class SplashViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var errorMessage: String?

    private let coordinator: CheckoutCoordinator
    private let checkoutViewModel: PrimerCheckoutViewModel

    init(coordinator: CheckoutCoordinator, checkoutViewModel: PrimerCheckoutViewModel) {
        self.coordinator = coordinator
        self.checkoutViewModel = checkoutViewModel
    }

    func initialize() async {
        do {
            // Initialize payment methods and other dependencies
            // TODO: Add initialization logic if needed

            // Small delay for UX (optional)
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

            // Navigate to payment methods list
            coordinator.navigate(to: .paymentMethodsList)

        } catch {
            errorMessage = "Failed to initialize: \(error.localizedDescription)"
            // Handle error - maybe show retry button or navigate to error state
        }
    }

    static func create(container: ContainerProtocol) async throws -> SplashViewModel {
        let coordinator = try await container.resolve(CheckoutCoordinator.self)
        let checkoutViewModel = try await container.resolve(PrimerCheckoutViewModel.self)
        return SplashViewModel(coordinator: coordinator, checkoutViewModel: checkoutViewModel)
    }
}
