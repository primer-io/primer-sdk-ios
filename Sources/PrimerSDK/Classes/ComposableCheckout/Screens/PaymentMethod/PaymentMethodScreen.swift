import SwiftUI

@available(iOS 15.0, *)
struct PaymentMethodScreen: View {
    @StateObject private var viewModel: PaymentMethodScreenViewModel
    @Environment(\.designTokens) private var tokens

    let paymentMethod: PaymentMethodProtocol

    init(paymentMethod: PaymentMethodProtocol, viewModel: PaymentMethodScreenViewModel) {
        self.paymentMethod = paymentMethod
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            headerView

            // Payment method content
            paymentMethod.defaultContent()
                .padding(16)
        }
        .background(tokens?.primerColorBackground ?? .white)
        .navigationBarHidden(true)
        .task {
            await viewModel.setupPaymentMethod(paymentMethod)
        }
    }

    private var headerView: some View {
        HStack {
            Button(action: {
                viewModel.goBack()
            }, label: {
                HStack {
                    Image(systemName: "arrow.backward")
                    Text("Back")
                }
                .foregroundColor(tokens?.primerColorBrand ?? .blue)
            })
            .buttonStyle(.borderless)

            Spacer()

            Text(paymentMethod.name ?? "Payment Method")
                .font(.headline)
                .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)

            Spacer()
        }
        .padding(16)
    }

    static func create(paymentMethod: PaymentMethodProtocol, container: ContainerProtocol) async throws -> PaymentMethodScreen {
        let viewModel = try await PaymentMethodScreenViewModel.create(container: container)
        return PaymentMethodScreen(paymentMethod: paymentMethod, viewModel: viewModel)
    }
}
