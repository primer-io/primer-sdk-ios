import SwiftUI

@available(iOS 15.0, *)
struct PaymentMethodButton: View {
    let paymentMethod: PaymentMethodDisplayModel
    let onTap: () -> Void
    @Environment(\.designTokens) private var designTokens

    private var backgroundColor: Color {
        paymentMethod.backgroundColor ?? designTokens?.primerColorGray000 ?? .white
    }

    private var borderColor: Color {
        paymentMethod.borderColor ?? designTokens?.primerColorBorderOutlinedDefault ?? .gray.opacity(0.3)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: PaymentMethodsListLayout.buttonSpacing) {
                // Payment method icon
                if let iconName = paymentMethod.iconName {
                    Image(systemName: iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(
                            width: PaymentMethodsListLayout.iconWidth,
                            height: PaymentMethodsListLayout.iconHeight
                        )
                        .foregroundColor(paymentMethod.textColor)
                }

                // Payment method name
                Text(paymentMethod.name)
                    .font(.system(
                        size: PaymentMethodsListTypography.buttonTextSize,
                        weight: PaymentMethodsListTypography.buttonTextWeight
                    ))
                    .foregroundColor(paymentMethod.textColor)

                Spacer()
            }
            .padding(.horizontal, PaymentMethodsListLayout.horizontalPadding)
            .frame(height: PaymentMethodsListLayout.buttonHeight)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: PaymentMethodsListLayout.buttonCornerRadius)
                    .stroke(borderColor, lineWidth: PaymentMethodsListLayout.buttonBorderWidth)
            )
            .cornerRadius(PaymentMethodsListLayout.buttonCornerRadius)
        }
        .disabled(!paymentMethod.isEnabled)
        .opacity(paymentMethod.isEnabled ? 1.0 : 0.6)
        .accessibility(identifier: PaymentMethodsListAccessibility.paymentMethodButtonPrefix + paymentMethod.id)
        .accessibility(label: Text(paymentMethod.accessibilityLabel))
        .accessibility(hint: Text(paymentMethod.isEnabled ? "Double tap to select this payment method" : "This payment method is not available"))
    }
}
