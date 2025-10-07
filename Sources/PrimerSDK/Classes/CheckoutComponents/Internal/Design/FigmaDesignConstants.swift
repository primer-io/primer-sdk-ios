import UIKit

internal struct FigmaDesignConstants {

    // MARK: - Input Field Dimensions
    /// Standard input field height as per Figma design (44px)
    static let inputFieldHeight: CGFloat = 44

    // MARK: - Spacing
    /// Vertical spacing between main form sections (12px)
    static let sectionSpacing: CGFloat = 12

    /// Spacing between label and input field (4px)
    static let labelInputSpacing: CGFloat = 4

    /// Spacing between card network badges (4px)
    static let cardBadgeSpacing: CGFloat = 4

    /// Horizontal spacing between side-by-side inputs like expiry/cvv (12px)
    static let horizontalInputSpacing: CGFloat = 12

    /// Internal padding for input fields (12px all sides)
    static let inputFieldPadding: CGFloat = 12

    // MARK: - Card Network Badges
    /// Height of card network badges (16px)
    static let cardBadgeHeight: CGFloat = 16

    /// Width of card network badges (24px - standard credit card aspect ratio)
    static let cardBadgeWidth: CGFloat = 24

    /// Border radius for card network badges (2px)
    static let cardBadgeRadius: CGFloat = 2

    // MARK: - Input Field Styling
    /// Border radius for input fields (4px)
    static let inputFieldRadius: CGFloat = 4

    /// Very subtle border color as per Figma: rgba(33,33,33,0.02)
    static let inputFieldBorderColor: UIColor = UIColor(red: 33/255, green: 33/255, blue: 33/255, alpha: 0.02)

    /// Input field background color (white)
    static let inputFieldBackgroundColor: UIColor = UIColor.white

    /// Input field text color (dark gray #212121)
    static let inputFieldTextColor: UIColor = UIColor(red: 33/255, green: 33/255, blue: 33/255, alpha: 1.0)

    // MARK: - Typography
    /// Font size for input field labels (12px)
    static let labelFontSize: CGFloat = 12

    /// Font size for input field values (16px)
    static let inputFontSize: CGFloat = 16

    /// Line height for labels (16px)
    static let labelLineHeight: CGFloat = 16

    /// Line height for input values (20px)
    static let inputLineHeight: CGFloat = 20

    /// Letter spacing for input text (-0.2px)
    static let inputLetterSpacing: CGFloat = -0.2

    // MARK: - Card Network Icon Dimensions
    /// Size for card network icon in input field trailing icon (28x20px)
    static let cardNetworkIconWidth: CGFloat = 28
    static let cardNetworkIconHeight: CGFloat = 20
    static let cardNetworkIconRadius: CGFloat = 2
}
