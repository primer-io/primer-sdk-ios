import SwiftUI

@available(iOS 15.0, *)
struct PaymentMethodsListScreen: View {
    @StateObject private var viewModel: PaymentMethodsListScreenViewModel
    @Environment(\.designTokens) private var tokens

    init(viewModel: PaymentMethodsListScreenViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Payment methods list with integrated cancel button
            PaymentMethodsListView(
                amount: viewModel.amount,
                paymentMethods: viewModel.paymentMethods,
                onPaymentMethodSelected: viewModel.handlePaymentMethodSelection,
                onCancel: viewModel.handleCancelAction
            )
        }
        .background(tokens?.primerColorBackground ?? .white)
        .task {
            await viewModel.loadPaymentMethods()
        }
    }

    static func create(container: ContainerProtocol) async throws -> PaymentMethodsListScreen {
        let viewModel = try await PaymentMethodsListScreenViewModel.create(container: container)
        return PaymentMethodsListScreen(viewModel: viewModel)
    }
}
