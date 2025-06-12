import Foundation
import Combine
import SwiftUI

@available(iOS 15.0, *)
@MainActor
final class PaymentMethodScreenViewModel: ObservableObject {
    @Published var isProcessing = false
    @Published var errorMessage: String?

    private let coordinator: CheckoutCoordinator
    private var cancellables = Set<AnyCancellable>()

    init(coordinator: CheckoutCoordinator) {
        self.coordinator = coordinator
    }

    func setupPaymentMethod(_ method: PaymentMethodProtocol) async {
        // Setup any method-specific configuration
    }

    func goBack() {
        coordinator.goBack()
    }

    func processPayment() async {
        isProcessing = true

        do {
            // Process payment logic
            let result = CheckoutPaymentResult(paymentId: "123", amount: "$99.00", method: "Card")
            coordinator.handlePaymentSuccess(result)
        } catch {
            let paymentError = CheckoutPaymentError(code: "PAYMENT_FAILED", message: error.localizedDescription, details: nil)
            coordinator.handlePaymentFailure(paymentError)
        }

        isProcessing = false
    }

    static func create(container: ContainerProtocol) async throws -> PaymentMethodScreenViewModel {
        let coordinator = try await container.resolve(CheckoutCoordinator.self)
        return PaymentMethodScreenViewModel(coordinator: coordinator)
    }
}
