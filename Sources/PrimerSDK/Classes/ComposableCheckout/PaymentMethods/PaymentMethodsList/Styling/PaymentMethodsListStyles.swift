import SwiftUI

// Custom modifiers for consistent styling
@available(iOS 15.0, *)
struct PaymentMethodButtonStyle: ViewModifier {
    let isEnabled: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(isEnabled ? 1.0 : 0.98)
            .animation(.easeInOut(duration: 0.1), value: isEnabled)
    }
}

@available(iOS 15.0, *)
extension View {
    func paymentMethodButtonStyle(isEnabled: Bool = true) -> some View {
        modifier(PaymentMethodButtonStyle(isEnabled: isEnabled))
    }
}

// Preview helpers
#if DEBUG
@available(iOS 15.0, *)
extension PaymentMethodDisplayModel {
    static var previewData: [PaymentMethodDisplayModel] {
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
            .card()
        ]
    }
}

@available(iOS 15.0, *)
struct PaymentMethodsListView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentMethodsListView(
            amount: "Pay $99.00",
            onPaymentMethodSelected: { _ in }
        )
        .environment(\.designTokens, nil) // Use nil for preview - components handle fallback colors
    }
}
#endif
