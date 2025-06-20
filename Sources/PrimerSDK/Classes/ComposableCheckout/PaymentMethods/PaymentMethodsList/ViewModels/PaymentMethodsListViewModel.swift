import SwiftUI

@available(iOS 15.0, *)
@MainActor
final class PaymentMethodsListViewModel: ObservableObject, LogReporter {
    @Published var paymentMethods: [PaymentMethodDisplayModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var container: (any ContainerProtocol)?

    init() {
        self.container = DIContainer.currentSync
    }

    func loadPaymentMethods() async {
        logger.info(message: "🔄 [PaymentMethodsListViewModel] Loading payment methods...")
        isLoading = true
        errorMessage = nil

        do {
            // Get available payment methods from existing system
            guard let container = container else {
                logger.error(message: "❌ [PaymentMethodsListViewModel] Container unavailable")
                throw ContainerError.containerUnavailable
            }

            logger.debug(message: "✅ [PaymentMethodsListViewModel] Container available, resolving PaymentMethodsProvider...")
            let paymentMethodsProvider: PaymentMethodsProvider = try await container.resolve(PaymentMethodsProvider.self)
            logger.debug(message: "✅ [PaymentMethodsListViewModel] PaymentMethodsProvider resolved, getting available methods...")
            let availableMethods = await paymentMethodsProvider.getAvailablePaymentMethods()
            logger.info(message: "📋 [PaymentMethodsListViewModel] Received \(availableMethods.count) payment methods from provider")

            for (index, method) in availableMethods.enumerated() {
                logger.debug(message: "   \(index): \(method.name ?? "Unknown") - Type: \(method.type.rawValue)")
            }

            // Convert to display models
            paymentMethods = availableMethods.compactMap { method in
                let displayModel = convertToDisplayModel(method)
                logger.debug(message: "🔄 [PaymentMethodsListViewModel] Converted \(method.name ?? "Unknown") to display model: \(displayModel?.name ?? "Failed")")
                return displayModel
            }

            logger.info(message: "✅ [PaymentMethodsListViewModel] Successfully loaded \(paymentMethods.count) payment methods from real provider")

        } catch {
            logger.error(message: "❌ [PaymentMethodsListViewModel] Failed to load payment methods: \(error.localizedDescription)")
            errorMessage = "Failed to load payment methods: \(error.localizedDescription)"
            // Fallback to mock data for development
            paymentMethods = createMockPaymentMethods()
            logger.warn(message: "🔄 [PaymentMethodsListViewModel] Using mock data with \(paymentMethods.count) payment methods")
        }

        isLoading = false
        logger.info(message: "✅ [PaymentMethodsListViewModel] Payment methods loading completed. Final count: \(paymentMethods.count)")
    }

    func selectPaymentMethod(_ paymentMethod: PaymentMethodDisplayModel) {
        // Analytics tracking
        // TODO: Add analytics event for payment method selection
        logger.info(message: "🎯 [PaymentMethodsListViewModel] Selected payment method: \(paymentMethod.name)")
    }

    // MARK: - Private Methods

    private func convertToDisplayModel(_ paymentMethod: any PaymentMethodProtocol) -> PaymentMethodDisplayModel? {
        // Convert the Hashable ID to String for our use case
        let idString = String(describing: paymentMethod.id)

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

    private func createMockPaymentMethods() -> [PaymentMethodDisplayModel] {
        [
            .applePay(),
            .payPal(),
            PaymentMethodDisplayModel(
                id: "ideal",
                name: "iDEAL",
                iconName: "ideal_logo",
                backgroundColor: Color(red: 0.86, green: 0.16, blue: 0.53),
                textColor: .white,
                borderColor: nil,
                isEnabled: true,
                accessibilityLabel: "Pay with iDEAL"
            ),
            PaymentMethodDisplayModel(
                id: "klarna",
                name: "Klarna",
                iconName: "klarna_logo",
                backgroundColor: Color(red: 0.11, green: 0.11, blue: 0.33),
                textColor: .white,
                borderColor: nil,
                isEnabled: true,
                accessibilityLabel: "Pay with Klarna"
            ),
            .card()
        ]
    }
}
