import SwiftUI

@available(iOS 15.0, *)
struct PaymentMethodsHeader: View {
    let amount: String
    let onCancel: () -> Void
    @Environment(\.designTokens) private var designTokens

    var body: some View {
        VStack(alignment: .leading, spacing: PaymentMethodsListLayout.titleToSubtitleSpacing) {
            // Top bar with amount and cancel
            HStack {
                Text(amount)
                    .font(.system(
                        size: PaymentMethodsListTypography.titleSize,
                        weight: PaymentMethodsListTypography.titleWeight
                    ))
                    .foregroundColor(designTokens?.primerColorTextPrimary ?? .primary)
                    .accessibility(identifier: PaymentMethodsListAccessibility.headerAmountIdentifier)

                Spacer()

                Button("Cancel", action: onCancel)
                    .font(.system(
                        size: PaymentMethodsListTypography.cancelButtonSize,
                        weight: PaymentMethodsListTypography.cancelButtonWeight
                    ))
                    .foregroundColor(designTokens?.primerColorTextLink ?? .blue)
                    .accessibility(identifier: PaymentMethodsListAccessibility.cancelButtonIdentifier)
            }

            // Subtitle
            Text("Choose payment method")
                .font(.system(
                    size: PaymentMethodsListTypography.subtitleSize,
                    weight: PaymentMethodsListTypography.subtitleWeight
                ))
                .foregroundColor(designTokens?.primerColorTextSecondary ?? .secondary)
                .accessibility(identifier: PaymentMethodsListAccessibility.headerSubtitleIdentifier)
        }
        .padding(.horizontal, PaymentMethodsListLayout.horizontalPadding)
    }
}
