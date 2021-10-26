internal struct Fontsize {

    static let title = 20
    static let subtitle = 10
    static let amountLabel = 24
    static let `default` = 14
    static let system = 12
    static let error = 10
    static let mainButtonTitle = 14
    static let paymentMethodButtonTitle = 14
}

internal struct Layout {
    
    struct View {
        static let cornerRadius: CGFloat = 0.0
        static let safeArea: CGFloat = 10.0
    }

    struct PaymentMethodButton {
        static let cornerRadius: CGFloat = 4.0
        static let borderWidth: CGFloat = 1.0
    }

    struct MainButton {
        static let cornerRadius: CGFloat = 4.0
        static let borderWidth: CGFloat = 1.0
    }
}
