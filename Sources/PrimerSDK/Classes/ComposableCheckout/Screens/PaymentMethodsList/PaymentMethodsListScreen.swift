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
            // Header
            headerView

            // Payment methods list
            PaymentMethodsListView(
                amount: viewModel.amount,
                paymentMethods: viewModel.paymentMethods,
                onPaymentMethodSelected: viewModel.handlePaymentMethodSelection
            )
        }
        .background(tokens?.primerColorBackground ?? .white)
        .task {
            await viewModel.loadPaymentMethods()
        }
    }

    private var headerView: some View {
        Text("Select Payment Method")
            .font(.title2)
            .fontWeight(.semibold)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)
            .padding(.horizontal, 16)
    }

    static func create(container: ContainerProtocol) async throws -> PaymentMethodsListScreen {
        let viewModel = try await PaymentMethodsListScreenViewModel.create(container: container)
        return PaymentMethodsListScreen(viewModel: viewModel)
    }
}
