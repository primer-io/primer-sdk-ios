import UIKit

public enum PrimerTextFieldTheme {
    case outlined, underlined, doublelined
}

public struct CornerRadiusTheme {
    public let buttons, textFields, sheetView, confirmMandateList: CGFloat

    public init(
        buttons: CGFloat = 4,
        textFields: CGFloat = 2,
        sheetView: CGFloat = 12,
        confirmMandateList: CGFloat = 0
    ) {
        self.buttons = buttons
        self.textFields = textFields
        self.sheetView = sheetView
        self.confirmMandateList = confirmMandateList
    }
}

public struct FontColorTheme {
    public let applePay, creditCard, paypal, total, title, payButton, labels: UIColor

    public init(
        applePay: UIColor = .white,
        creditCard: UIColor = .black,
        paypal: UIColor = .black,
        total: UIColor = .black,
        title: UIColor = .black,
        payButton: UIColor = .white,
        labels: UIColor = .systemBlue
    ) {
        self.applePay = applePay
        self.creditCard = creditCard
        self.paypal = paypal
        self.total = total
        self.title = title
        self.payButton = payButton
        self.labels = labels
    }
}

public struct PrimerLayout {
    public let showMainTitle, showTopTitle, fullScreenOnly: Bool
    public let safeMargin: CGFloat
    public let textFieldHeight: CGFloat
    public let confirmMandateListItemHeight: CGFloat
    public let confirmMandateListMargin: CGFloat
    public let confirmMandateListTopMargin: CGFloat

    public init(
        showMainTitle: Bool = true,
        showTopTitle: Bool = true,
        fullScreenOnly: Bool = false,
        safeMargin: CGFloat = 16.0,
        textFieldHeight: CGFloat = 44.0,
        confirmMandateListItemHeight: CGFloat = 60.0,
        confirmMandateListMargin: CGFloat = 0.0,
        confirmMandateListTopMargin: CGFloat = 24
    ) {
        self.showMainTitle = showMainTitle
        self.showTopTitle = showTopTitle
        self.fullScreenOnly = fullScreenOnly
        self.safeMargin = safeMargin
        self.textFieldHeight = textFieldHeight
        self.confirmMandateListItemHeight = confirmMandateListItemHeight
        self.confirmMandateListMargin = confirmMandateListMargin
        self.confirmMandateListTopMargin = confirmMandateListTopMargin
    }
}

public struct PrimerFontTheme {
    let mainTitle: UIFont
    let successMessageFont: UIFont

    public init(
        mainTitle: UIFont = UIFont.systemFont(ofSize: 20),
        successMessageFont: UIFont = .systemFont(ofSize: 20)
    ) {
        self.mainTitle = mainTitle
        self.successMessageFont = successMessageFont
    }
}

public struct PrimerShadowTheme {
    var color: CGColor
    var opacity, radius: CGFloat
}

public protocol ColorTheme {
    var text1: UIColor { get } // heading
    var text2: UIColor { get } // body
    var text3: UIColor { get } // system
    var secondaryText1: UIColor { get }
    var main1: UIColor { get } // backgrounds
    var main2: UIColor { get } // cells, default buttons
    var tint1: UIColor { get } // border
    var neutral1: UIColor { get } //
    var disabled1: UIColor { get }
    var error1: UIColor { get }
    var success1: UIColor { get } // success message icon and navbar
}

@available(iOS 13.0, *)
struct DefaultColorTheme: ColorTheme {
    var text1: UIColor { return getColor(light: lightTheme.text1, dark: darkTheme.text1) }
    var text2: UIColor { return getColor(light: lightTheme.text2, dark: darkTheme.text2) }
    var text3: UIColor { return getColor(light: lightTheme.text3, dark: darkTheme.text3) }
    var secondaryText1: UIColor { return getColor(light: lightTheme.secondaryText1, dark: darkTheme.secondaryText1) }
    var main1: UIColor { return getColor(light: lightTheme.main1, dark: darkTheme.main1) }
    var main2: UIColor { return getColor(light: lightTheme.main2, dark: darkTheme.main2) }
    var tint1: UIColor { return getColor(light: lightTheme.tint1, dark: darkTheme.tint1) }
    var neutral1: UIColor { return getColor(light: lightTheme.neutral1, dark: darkTheme.neutral1) }
    var disabled1: UIColor { return getColor(light: lightTheme.disabled1, dark: darkTheme.disabled1) }
    var error1: UIColor { return getColor(light: lightTheme.error1, dark: darkTheme.error1) }
    var success1: UIColor { return getColor(light: lightTheme.success1, dark: darkTheme.success1) }

    let lightTheme: ColorTheme
    let darkTheme: ColorTheme

    init(
        lightTheme: ColorTheme,
        darkTheme: ColorTheme
    ) {
        self.lightTheme = lightTheme
        self.darkTheme = darkTheme
    }

    func getColor(light: UIColor, dark: UIColor) -> UIColor {
        return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
            if UITraitCollection.userInterfaceStyle == .dark {
                return dark
            } else {
                return light
            }
        }
    }
}

public struct PrimerDefaultTheme: ColorTheme {
    public var text1: UIColor
    public var text2: UIColor
    public var text3: UIColor
    public var secondaryText1: UIColor
    public var main1: UIColor
    public var main2: UIColor
    public var tint1: UIColor
    public var neutral1: UIColor
    public var disabled1: UIColor
    public var error1: UIColor
    public var success1: UIColor

    public init(
        text1: UIColor = .black,
        text2: UIColor = .white,
        text3: UIColor = .systemBlue,
        secondaryText1: UIColor = .lightGray,
        main1: UIColor = .white,
        main2: UIColor = UIColor(red: 0, green: 56.0/255, blue: 255.0/255, alpha: 1.0),
        tint1: UIColor = .systemBlue,
        neutral1: UIColor = .lightGray,
        disabled1: UIColor = .lightGray,
        error1: UIColor = .systemRed,
        success1: UIColor = .systemGreen
    ) {
        self.text1 = text1
        self.text2 = text2
        self.text3 = text3
        self.secondaryText1 = secondaryText1
        self.main1 = main1
        self.main2 = main2
        self.tint1 = tint1
        self.neutral1 = neutral1
        self.disabled1 = disabled1
        self.error1 = error1
        self.success1 = success1
    }
}

@available(iOS 13.0, *)
public struct PrimerDarkTheme: ColorTheme {
    public var text1: UIColor
    public var text2: UIColor
    public var text3: UIColor
    public var secondaryText1: UIColor
    public var main1: UIColor
    public var main2: UIColor
    public var tint1: UIColor
    public var neutral1: UIColor
    public var disabled1: UIColor
    public var error1: UIColor
    public var success1: UIColor

    public init(
        text1: UIColor = .white,
        text2: UIColor = .white,
        text3: UIColor = .systemBlue,
        secondaryText1: UIColor = .systemGray,
        main1: UIColor = .systemGray6,
        main2: UIColor = .systemGray5,
        tint1: UIColor = .systemBlue,
        neutral1: UIColor = .systemGray3,
        disabled1: UIColor = .systemGray3,
        error1: UIColor = .systemRed,
        success1: UIColor = .systemBlue
    ) {
        self.text1 = text1
        self.text2 = text2
        self.text3 = text3
        self.secondaryText1 = secondaryText1
        self.main1 = main1
        self.main2 = main2
        self.tint1 = tint1
        self.neutral1 = neutral1
        self.disabled1 = disabled1
        self.error1 = error1
        self.success1 = success1
    }
}
