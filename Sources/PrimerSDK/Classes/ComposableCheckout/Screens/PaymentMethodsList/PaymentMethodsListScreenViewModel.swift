import Foundation
import Combine
import SwiftUI

@available(iOS 15.0, *)
@MainActor
final class PaymentMethodsListScreenViewModel: ObservableObject {
    @Published var paymentMethods: [PaymentMethodDisplayModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let amount: String

    private let coordinator: CheckoutCoordinator
    private let checkoutViewModel: PrimerCheckoutViewModel
    private var allPaymentMethods: [any PaymentMethodProtocol] = []

    init(coordinator: CheckoutCoordinator, checkoutViewModel: PrimerCheckoutViewModel) {
        self.coordinator = coordinator
        self.checkoutViewModel = checkoutViewModel
        self.amount = "Pay $99.00" // TODO: Get from configuration
    }

    func loadPaymentMethods() async {
        isLoading = true

        // First try to get current payment methods synchronously if available
        let currentMethods = await checkoutViewModel.getCurrentPaymentMethods()
        if !currentMethods.isEmpty {
            allPaymentMethods = currentMethods
            paymentMethods = currentMethods.compactMap { PaymentMethodConverter.convertToDisplayModel($0) }
            isLoading = false
            return
        }

        // If no current methods, listen to the stream
        for await methods in checkoutViewModel.paymentMethods() {
            allPaymentMethods = methods
            paymentMethods = methods.compactMap { PaymentMethodConverter.convertToDisplayModel($0) }
            isLoading = false
            break // Get first emission
        }
    }

    func handlePaymentMethodSelection(_ displayModel: PaymentMethodDisplayModel) {
        // Convert display model to protocol method using PaymentMethodConverter
        let method = PaymentMethodConverter.findMatchingPaymentMethod(for: displayModel, in: allPaymentMethods)

        if let method = method {
            coordinator.handlePaymentMethodSelection(method)
        } else {
            errorMessage = "Could not find matching payment method"
        }
    }

    func handleCancelAction() {
        // Dismiss the entire Primer UI and notify the delegate
        PrimerUIManager.dismissPrimerUI(animated: true) {
            // The delegate's primerDidDismiss() will be called automatically
            // by the PrimerDelegateProxy
            PrimerDelegateProxy.primerDidDismiss(paymentMethodManagerCategories: [])
        }
    }

    static func create(container: ContainerProtocol) async throws -> PaymentMethodsListScreenViewModel {
        let coordinator = try await container.resolve(CheckoutCoordinator.self)
        let checkoutViewModel = try await container.resolve(PrimerCheckoutViewModel.self)
        return PaymentMethodsListScreenViewModel(coordinator: coordinator, checkoutViewModel: checkoutViewModel)
    }
}
