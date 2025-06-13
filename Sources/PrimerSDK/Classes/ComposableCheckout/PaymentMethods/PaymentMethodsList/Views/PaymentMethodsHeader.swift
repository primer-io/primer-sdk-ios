import SwiftUI

@available(iOS 15.0, *)
struct PaymentMethodsHeader: View {
    let amount: String
    let onCancel: () -> Void
    @Environment(\.designTokens) private var designTokens

    var body: some View {
        HStack(alignment: .top) {
            // Left side: Amount only
            Text(amount)
                .font(.system(
                    size: PaymentMethodsListTypography.titleSize,
                    weight: PaymentMethodsListTypography.titleWeight
                ))
                .foregroundColor(designTokens?.primerColorTextPrimary ?? .primary)
                .accessibility(identifier: PaymentMethodsListAccessibility.headerAmountIdentifier)
            
            Spacer()
            
            // Right side: Cancel button aligned to top
            Button("Cancel", action: onCancel)
                .font(.system(
                    size: PaymentMethodsListTypography.cancelButtonSize,
                    weight: PaymentMethodsListTypography.cancelButtonWeight
                ))
                .foregroundColor(designTokens?.primerColorTextPrimary ?? .primary)
                .accessibility(identifier: PaymentMethodsListAccessibility.cancelButtonIdentifier)
        }
        .padding(.horizontal, PaymentMethodsListLayout.horizontalPadding)
    }
}
