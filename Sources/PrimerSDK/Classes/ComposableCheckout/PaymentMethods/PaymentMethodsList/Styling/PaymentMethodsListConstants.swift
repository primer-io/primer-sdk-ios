import SwiftUI

@available(iOS 15.0, *)
enum PaymentMethodsListLayout {
    // Button dimensions (from Figma measurements)
    static let buttonHeight: CGFloat = 44         // h-11 = 44px
    static let buttonCornerRadius: CGFloat = 8    // radius/medium: 8
    static let buttonBorderWidth: CGFloat = 1

    // Spacing values (from Figma)
    static let buttonSpacing: CGFloat = 8         // gap-2 = 8px between payment method buttons
    static let horizontalPadding: CGFloat = 16    // p-4 = 16px screen edge margins
    static let headerToListSpacing: CGFloat = 24  // gap-6 = 24px header section to list
    static let titleToSubtitleSpacing: CGFloat = 12 // gap-3 = 12px between subtitle and buttons
    static let topSafeAreaPadding: CGFloat = 2    // py-0.5 = 2px below safe area

    // Icon dimensions
    static let iconWidth: CGFloat = 20            // aspect-[20/44] width portion
    static let iconHeight: CGFloat = 20           // Proportional to button height
}

@available(iOS 15.0, *)
enum PaymentMethodsListTypography {
    // Font sizes (from Figma design)
    static let titleSize: CGFloat = 24           // web/title-xlarge: size: 24
    static let titleWeight: Font.Weight = .semibold // weight: 550 (semibold)

    static let subtitleSize: CGFloat = 16        // web/title-large: size: 16
    static let subtitleWeight: Font.Weight = .medium // weight: 550 (medium)

    static let buttonTextSize: CGFloat = 16      // web/title-large: size: 16
    static let buttonTextWeight: Font.Weight = .medium // weight: 550 (medium)

    static let cancelButtonSize: CGFloat = 16    // web/title-large: size: 16
    static let cancelButtonWeight: Font.Weight = .medium // weight: 550 (medium)
}

@available(iOS 15.0, *)
enum PaymentMethodsListAccessibility {
    static let paymentMethodButtonPrefix = "payment_method_button_"
    static let headerAmountIdentifier = "payment_amount_label"
    static let headerSubtitleIdentifier = "choose_payment_method_label"
    static let cancelButtonIdentifier = "cancel_payment_button"
    static let listContainerIdentifier = "payment_methods_list"
}
