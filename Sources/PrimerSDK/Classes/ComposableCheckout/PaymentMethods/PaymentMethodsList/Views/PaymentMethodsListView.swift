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
                    ForEach(viewModel.paymentMethods) { paymentMethod in
                        PaymentMethodButton(
                            paymentMethod: paymentMethod,
                            onTap: {
                                viewModel.selectPaymentMethod(paymentMethod)
                                onPaymentMethodSelected(paymentMethod)
                            }
                        )
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
