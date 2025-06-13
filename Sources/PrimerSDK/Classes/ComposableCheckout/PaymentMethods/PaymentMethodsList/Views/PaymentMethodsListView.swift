import SwiftUI

@available(iOS 15.0, *)
struct PaymentMethodsListView: View {
    @Environment(\.designTokens) private var designTokens
    @Environment(\.presentationMode) private var presentationMode

    let amount: String
    let paymentMethods: [PaymentMethodDisplayModel]
    let onPaymentMethodSelected: (PaymentMethodDisplayModel) -> Void
    let onCancel: (() -> Void)?

    init(
        amount: String,
        paymentMethods: [PaymentMethodDisplayModel],
        onPaymentMethodSelected: @escaping (PaymentMethodDisplayModel) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self.amount = amount
        self.paymentMethods = paymentMethods
        self.onPaymentMethodSelected = onPaymentMethodSelected
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header section with proper spacing
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
            .padding(.bottom, PaymentMethodsListLayout.headerToListSpacing)

            // Subtitle above payment methods
            Text("Choose payment method")
                .font(.system(
                    size: PaymentMethodsListTypography.subtitleSize,
                    weight: PaymentMethodsListTypography.subtitleWeight
                ))
                .foregroundColor(designTokens?.primerColorTextSecondary ?? Color(red: 0.47, green: 0.47, blue: 0.48))
                .accessibility(identifier: PaymentMethodsListAccessibility.headerSubtitleIdentifier)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, PaymentMethodsListLayout.horizontalPadding)
                .padding(.bottom, PaymentMethodsListLayout.titleToSubtitleSpacing)

            // Payment methods list
            ScrollView {
                LazyVStack(spacing: PaymentMethodsListLayout.buttonSpacing) {
                    ForEach(Array(paymentMethods.enumerated()), id: \.element.id) { index, paymentMethod in
                        PaymentMethodButton(
                            paymentMethod: paymentMethod,
                            onTap: {
                                onPaymentMethodSelected(paymentMethod)
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                        .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.1), value: paymentMethods.count)
                    }
                }
                .padding(.horizontal, PaymentMethodsListLayout.horizontalPadding)
            }
            .accessibility(identifier: PaymentMethodsListAccessibility.listContainerIdentifier)

            Spacer()
        }
        .background(designTokens?.primerColorBackground ?? .white)
    }
}
