import SwiftUI

@available(iOS 15.0, *)
enum PaymentMethodsListLayout {
    // Button dimensions (from Figma measurements)
    static let buttonHeight: CGFloat = 56
    static let buttonCornerRadius: CGFloat = 8
    static let buttonBorderWidth: CGFloat = 1

    // Spacing values (from Figma)
    static let buttonSpacing: CGFloat = 12        // Between payment method buttons
    static let horizontalPadding: CGFloat = 16    // Screen edge margins
    static let headerToListSpacing: CGFloat = 24  // Header section to list
    static let titleToSubtitleSpacing: CGFloat = 8 // "Pay $X" to "Choose payment method"
    static let topSafeAreaPadding: CGFloat = 20   // Below safe area

    // Icon dimensions
    static let iconWidth: CGFloat = 24
    static let iconHeight: CGFloat = 24
}

@available(iOS 15.0, *)
enum PaymentMethodsListTypography {
    // Font sizes (from Figma design)
    static let titleSize: CGFloat = 34           // "Pay $99.00"
    static let titleWeight: Font.Weight = .bold

    static let subtitleSize: CGFloat = 16        // "Choose payment method"
    static let subtitleWeight: Font.Weight = .medium

    static let buttonTextSize: CGFloat = 16      // Payment method labels
    static let buttonTextWeight: Font.Weight = .medium

    static let cancelButtonSize: CGFloat = 16    // Cancel button
    static let cancelButtonWeight: Font.Weight = .medium
}

@available(iOS 15.0, *)
enum PaymentMethodsListAccessibility {
    static let paymentMethodButtonPrefix = "payment_method_button_"
    static let headerAmountIdentifier = "payment_amount_label"
    static let headerSubtitleIdentifier = "choose_payment_method_label"
    static let cancelButtonIdentifier = "cancel_payment_button"
    static let listContainerIdentifier = "payment_methods_list"
}
