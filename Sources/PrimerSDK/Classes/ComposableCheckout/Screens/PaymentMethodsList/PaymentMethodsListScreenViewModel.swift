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
    private var cancellables = Set<AnyCancellable>()
    private var allPaymentMethods: [PaymentMethodProtocol] = []

    init(coordinator: CheckoutCoordinator, checkoutViewModel: PrimerCheckoutViewModel) {
        self.coordinator = coordinator
        self.checkoutViewModel = checkoutViewModel
        self.amount = "Pay $99.00" // TODO: Get from configuration

        setupObservation()
    }

    func loadPaymentMethods() async {
        isLoading = true

        // First try to get current payment methods synchronously if available
        let currentMethods = await checkoutViewModel.getCurrentPaymentMethods()
        if !currentMethods.isEmpty {
            allPaymentMethods = currentMethods
            paymentMethods = currentMethods.compactMap { convertToDisplayModel($0) }
            isLoading = false
            return
        }

        // If no current methods, listen to the stream
        for await methods in checkoutViewModel.paymentMethods() {
            allPaymentMethods = methods
            paymentMethods = methods.compactMap { convertToDisplayModel($0) }
            isLoading = false
            break // Get first emission
        }
    }

    func handlePaymentMethodSelection(_ displayModel: PaymentMethodDisplayModel) {
        // Convert display model to protocol method (existing logic)
        let method = findMatchingPaymentMethod(for: displayModel)

        if let method = method {
            coordinator.handlePaymentMethodSelection(method)
        } else {
            errorMessage = "Could not find matching payment method"
        }
    }

    private func findMatchingPaymentMethod(for displayModel: PaymentMethodDisplayModel) -> PaymentMethodProtocol? {
        // Existing conversion logic from PrimerCheckoutSheet
        switch displayModel.id {
        case "payment_card":
            return allPaymentMethods.first(where: { $0.type == .paymentCard })
        case "apple_pay":
            return allPaymentMethods.first(where: { $0.type == .applePay })
        case "paypal":
            return allPaymentMethods.first(where: { $0.type == .payPal })
        default:
            return allPaymentMethods.first(where: {
                String(describing: $0.id) == displayModel.id || $0.name == displayModel.name
            })
        }
    }

    private func convertToDisplayModel(_ paymentMethod: any PaymentMethodProtocol) -> PaymentMethodDisplayModel? {
        // Use the payment method type for better matching instead of ID
        switch paymentMethod.type {
        case .applePay:
            return .applePay()
        case .payPal:
            return .payPal()
        case .paymentCard:
            return .card()
        default:
            // Generic conversion for other payment methods
            let idString = String(describing: paymentMethod.id)
            return PaymentMethodDisplayModel(
                id: idString,
                name: paymentMethod.name ?? "Unknown Payment Method",
                iconName: "creditcard", // Default icon
                backgroundColor: nil,
                textColor: .primary,
                borderColor: nil,
                isEnabled: true,
                accessibilityLabel: "Pay with \(paymentMethod.name ?? "Unknown Payment Method")"
            )
        }
    }

    private func setupObservation() {
        // Setup any additional observation if needed
    }

    static func create(container: ContainerProtocol) async throws -> PaymentMethodsListScreenViewModel {
        let coordinator = try await container.resolve(CheckoutCoordinator.self)
        let checkoutViewModel = try await container.resolve(PrimerCheckoutViewModel.self)
        return PaymentMethodsListScreenViewModel(coordinator: coordinator, checkoutViewModel: checkoutViewModel)
    }
}
