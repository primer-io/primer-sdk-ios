import SwiftUI

@available(iOS 15.0, *)
struct PaymentMethodsListView: View {
    @StateObject private var viewModel = PaymentMethodsListViewModel()
    @Environment(\.designTokens) private var designTokens
    @Environment(\.presentationMode) private var presentationMode

    let amount: String
    let onPaymentMethodSelected: (PaymentMethodDisplayModel) -> Void
    let onCancel: (() -> Void)?

    init(amount: String, onPaymentMethodSelected: @escaping (PaymentMethodDisplayModel) -> Void, onCancel: (() -> Void)? = nil) {
        self.amount = amount
        self.onPaymentMethodSelected = onPaymentMethodSelected
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header section
            PaymentMethodsHeader(
                amount: amount,
                onCancel: {
                    if let onCancel = onCancel {
                        onCancel()
                    } else {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
            .padding(.top, PaymentMethodsListLayout.topSafeAreaPadding)

            Spacer()
                .frame(height: PaymentMethodsListLayout.headerToListSpacing)

            // Payment methods list
            ScrollView {
                LazyVStack(spacing: PaymentMethodsListLayout.buttonSpacing) {
                    ForEach(Array(viewModel.paymentMethods.enumerated()), id: \.element.id) { index, paymentMethod in
                        PaymentMethodButton(
                            paymentMethod: paymentMethod,
                            onTap: {
                                viewModel.selectPaymentMethod(paymentMethod)
                                onPaymentMethodSelected(paymentMethod)
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                        .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.1), value: viewModel.paymentMethods.count)
                    }
                }
                .padding(.horizontal, PaymentMethodsListLayout.horizontalPadding)
            }
            .accessibility(identifier: PaymentMethodsListAccessibility.listContainerIdentifier)

            Spacer()
        }
        .background(designTokens?.primerColorBackground ?? .white)
        .task {
            await viewModel.loadPaymentMethods()
        }
    }
}
