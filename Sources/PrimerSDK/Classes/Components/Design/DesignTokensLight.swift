// swiftlint:disable all
import SwiftUI

internal class DesignTokensLight: Decodable {
    public var primerColorBackground: Color? = Color(red: 1.000, green: 1.000, blue: 1.000, opacity: 1)
    public var primerColorTextPrimary: Color? = Color(red: 0.129, green: 0.129, blue: 0.129, opacity: 1)
    public var primerColorTextPlaceholder: Color? = Color(red: 0.620, green: 0.620, blue: 0.620, opacity: 1)
    public var primerColorTextDisabled: Color? = Color(red: 0.741, green: 0.741, blue: 0.741, opacity: 1)
    public var primerColorTextNegative: Color? = Color(red: 0.706, green: 0.196, blue: 0.294, opacity: 1)
    public var primerColorTextLink: Color? = Color(red: 0.133, green: 0.439, blue: 0.957, opacity: 1)
    public var primerColorTextSecondary: Color? = Color(red: 0.459, green: 0.459, blue: 0.459, opacity: 1)
    public var primerColorBorderOutlinedDefault: Color? = Color(red: 0.878, green: 0.878, blue: 0.878, opacity: 1)
    public var primerColorBorderOutlinedHover: Color? = Color(red: 0.741, green: 0.741, blue: 0.741, opacity: 1)
    public var primerColorBorderOutlinedActive: Color? = Color(red: 0.620, green: 0.620, blue: 0.620, opacity: 1)
    public var primerColorBorderOutlinedFocus: Color? = Color(red: 0.184, green: 0.596, blue: 1.000, opacity: 1)
    public var primerColorBorderOutlinedDisabled: Color? = Color(red: 0.933, green: 0.933, blue: 0.933, opacity: 1)
    public var primerColorBorderOutlinedLoading: Color? = Color(red: 0.933, green: 0.933, blue: 0.933, opacity: 1)
    public var primerColorBorderOutlinedSelected: Color? = Color(red: 0.184, green: 0.596, blue: 1.000, opacity: 1)
    public var primerColorBorderOutlinedError: Color? = Color(red: 1.000, green: 0.447, blue: 0.475, opacity: 1)
    public var primerColorBorderTransparentDefault: Color? = Color(red: 1.000, green: 1.000, blue: 1.000, opacity: 0)
    public var primerColorBorderTransparentHover: Color? = Color(red: 1.000, green: 1.000, blue: 1.000, opacity: 0)
    public var primerColorBorderTransparentActive: Color? = Color(red: 1.000, green: 1.000, blue: 1.000, opacity: 0)
    public var primerColorBorderTransparentFocus: Color? = Color(red: 0.184, green: 0.596, blue: 1.000, opacity: 1)
    public var primerColorBorderTransparentDisabled: Color? = Color(red: 1.000, green: 1.000, blue: 1.000, opacity: 0)
    public var primerColorBorderTransparentSelected: Color? = Color(red: 1.000, green: 1.000, blue: 1.000, opacity: 0)
    public var primerColorIconPrimary: Color? = Color(red: 0.129, green: 0.129, blue: 0.129, opacity: 1)
    public var primerColorIconDisabled: Color? = Color(red: 0.741, green: 0.741, blue: 0.741, opacity: 1)
    public var primerColorIconNegative: Color? = Color(red: 1.000, green: 0.447, blue: 0.475, opacity: 1)
    public var primerColorIconPositive: Color? = Color(red: 0.243, green: 0.714, blue: 0.561, opacity: 1)
    public var primerColorFocus: Color? = Color(red: 0.184, green: 0.596, blue: 1.000, opacity: 1)
    public var primerColorLoader: Color? = Color(red: 0.184, green: 0.596, blue: 1.000, opacity: 1)
    public var primerColorGray100: Color? = Color(red: 0.961, green: 0.961, blue: 0.961, opacity: 1)
    public var primerColorGray200: Color? = Color(red: 0.933, green: 0.933, blue: 0.933, opacity: 1)
    public var primerColorGray300: Color? = Color(red: 0.878, green: 0.878, blue: 0.878, opacity: 1)
    public var primerColorGray400: Color? = Color(red: 0.741, green: 0.741, blue: 0.741, opacity: 1)
    public var primerColorGray500: Color? = Color(red: 0.620, green: 0.620, blue: 0.620, opacity: 1)
    public var primerColorGray600: Color? = Color(red: 0.459, green: 0.459, blue: 0.459, opacity: 1)
    public var primerColorGray900: Color? = Color(red: 0.129, green: 0.129, blue: 0.129, opacity: 1)
    public var primerColorGray000: Color? = Color(red: 1.000, green: 1.000, blue: 1.000, opacity: 1)
    public var primerColorGreen500: Color? = Color(red: 0.243, green: 0.714, blue: 0.561, opacity: 1)
    public var primerColorBrand: Color? = Color(red: 0.184, green: 0.596, blue: 1.000, opacity: 1)
    public var primerColorRed100: Color? = Color(red: 1.000, green: 0.925, blue: 0.925, opacity: 1)
    public var primerColorRed500: Color? = Color(red: 1.000, green: 0.447, blue: 0.475, opacity: 1)
    public var primerColorRed900: Color? = Color(red: 0.706, green: 0.196, blue: 0.294, opacity: 1)
    public var primerColorBlue500: Color? = Color(red: 0.224, green: 0.616, blue: 1.000, opacity: 1)
    public var primerColorBlue900: Color? = Color(red: 0.133, green: 0.439, blue: 0.957, opacity: 1)
    public var primerRadiusMedium: CGFloat? = 8
    public var primerRadiusSmall: CGFloat? = 4
    public var primerRadiusLarge: CGFloat? = 12
    public var primerRadiusXsmall: CGFloat? = 2
    public var primerRadiusBase: CGFloat? = 4
    public var primerTypographyBrand: String? = "Inter"
    public var primerTypographyTitleXlargeFont: String? = "Inter"
    public var primerTypographyTitleXlargeLetterSpacing: CGFloat? = -0.6
    public var primerTypographyTitleXlargeWeight: CGFloat? = 550
    public var primerTypographyTitleXlargeSize: CGFloat? = 24
    public var primerTypographyTitleXlargeLineHeight: CGFloat? = 32
    public var primerTypographyTitleLargeFont: String? = "Inter"
    public var primerTypographyTitleLargeLetterSpacing: CGFloat? = -0.2
    public var primerTypographyTitleLargeWeight: CGFloat? = 550
    public var primerTypographyTitleLargeSize: CGFloat? = 16
    public var primerTypographyTitleLargeLineHeight: CGFloat? = 20
    public var primerTypographyBodyLargeFont: String? = "Inter"
    public var primerTypographyBodyLargeLetterSpacing: CGFloat? = -0.2
    public var primerTypographyBodyLargeWeight: CGFloat? = 400
    public var primerTypographyBodyLargeSize: CGFloat? = 16
    public var primerTypographyBodyLargeLineHeight: CGFloat? = 20
    public var primerTypographyBodyMediumFont: String? = "Inter"
    public var primerTypographyBodyMediumLetterSpacing: CGFloat? = 0
    public var primerTypographyBodyMediumWeight: CGFloat? = 400
    public var primerTypographyBodyMediumSize: CGFloat? = 14
    public var primerTypographyBodyMediumLineHeight: CGFloat? = 20
    public var primerTypographyBodySmallFont: String? = "Inter"
    public var primerTypographyBodySmallLetterSpacing: CGFloat? = 0
    public var primerTypographyBodySmallWeight: CGFloat? = 400
    public var primerTypographyBodySmallSize: CGFloat? = 12
    public var primerTypographyBodySmallLineHeight: CGFloat? = 16
    public var primerSpaceXxsmall: CGFloat? = 2
    public var primerSpaceXsmall: CGFloat? = 4
    public var primerSpaceSmall: CGFloat? = 8
    public var primerSpaceMedium: CGFloat? = 12
    public var primerSpaceLarge: CGFloat? = 16
    public var primerSpaceXlarge: CGFloat? = 20
    public var primerSpaceBase: CGFloat? = 4
    public var primerSizeSmall: CGFloat? = 16
    public var primerSizeMedium: CGFloat? = 20
    public var primerSizeLarge: CGFloat? = 24
    public var primerSizeXlarge: CGFloat? = 32
    public var primerSizeXxlarge: CGFloat? = 44
    public var primerSizeXxxlarge: CGFloat? = 56
    public var primerSizeBase: CGFloat? = 4

    enum CodingKeys: String, CodingKey {
        case primerColorBackground
        case primerColorTextPrimary
        case primerColorTextPlaceholder
        case primerColorTextDisabled
        case primerColorTextNegative
        case primerColorTextLink
        case primerColorTextSecondary
        case primerColorBorderOutlinedDefault
        case primerColorBorderOutlinedHover
        case primerColorBorderOutlinedActive
        case primerColorBorderOutlinedFocus
        case primerColorBorderOutlinedDisabled
        case primerColorBorderOutlinedLoading
        case primerColorBorderOutlinedSelected
        case primerColorBorderOutlinedError
        case primerColorBorderTransparentDefault
        case primerColorBorderTransparentHover
        case primerColorBorderTransparentActive
        case primerColorBorderTransparentFocus
        case primerColorBorderTransparentDisabled
        case primerColorBorderTransparentSelected
        case primerColorIconPrimary
        case primerColorIconDisabled
        case primerColorIconNegative
        case primerColorIconPositive
        case primerColorFocus
        case primerColorLoader
        case primerColorGray100
        case primerColorGray200
        case primerColorGray300
        case primerColorGray400
        case primerColorGray500
        case primerColorGray600
        case primerColorGray900
        case primerColorGray000
        case primerColorGreen500
        case primerColorBrand
        case primerColorRed100
        case primerColorRed500
        case primerColorRed900
        case primerColorBlue500
        case primerColorBlue900
        case primerRadiusMedium
        case primerRadiusSmall
        case primerRadiusLarge
        case primerRadiusXsmall
        case primerRadiusBase
        case primerTypographyBrand
        case primerTypographyTitleXlargeFont
        case primerTypographyTitleXlargeLetterSpacing
        case primerTypographyTitleXlargeWeight
        case primerTypographyTitleXlargeSize
        case primerTypographyTitleXlargeLineHeight
        case primerTypographyTitleLargeFont
        case primerTypographyTitleLargeLetterSpacing
        case primerTypographyTitleLargeWeight
        case primerTypographyTitleLargeSize
        case primerTypographyTitleLargeLineHeight
        case primerTypographyBodyLargeFont
        case primerTypographyBodyLargeLetterSpacing
        case primerTypographyBodyLargeWeight
        case primerTypographyBodyLargeSize
        case primerTypographyBodyLargeLineHeight
        case primerTypographyBodyMediumFont
        case primerTypographyBodyMediumLetterSpacing
        case primerTypographyBodyMediumWeight
        case primerTypographyBodyMediumSize
        case primerTypographyBodyMediumLineHeight
        case primerTypographyBodySmallFont
        case primerTypographyBodySmallLetterSpacing
        case primerTypographyBodySmallWeight
        case primerTypographyBodySmallSize
        case primerTypographyBodySmallLineHeight
        case primerSpaceXxsmall
        case primerSpaceXsmall
        case primerSpaceSmall
        case primerSpaceMedium
        case primerSpaceLarge
        case primerSpaceXlarge
        case primerSpaceBase
        case primerSizeSmall
        case primerSizeMedium
        case primerSizeLarge
        case primerSizeXlarge
        case primerSizeXxlarge
        case primerSizeXxxlarge
        case primerSizeBase
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let primerColorBackgroundComponents = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorBackground) {
            self.primerColorBackground = Color(
                red: primerColorBackgroundComponents[0],
                green: primerColorBackgroundComponents[1],
                blue: primerColorBackgroundComponents[2],
                opacity: primerColorBackgroundComponents[3]
            )
        }
        
        if let primerColorTextPrimaryComponents = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorTextPrimary) {
            self.primerColorTextPrimary = Color(
                red: primerColorTextPrimaryComponents[0],
                green: primerColorTextPrimaryComponents[1],
                blue: primerColorTextPrimaryComponents[2],
                opacity: primerColorTextPrimaryComponents[3]
            )
        }
        
        if let primerColorTextPlaceholderComponents = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorTextPlaceholder) {
            self.primerColorTextPlaceholder = Color(
                red: primerColorTextPlaceholderComponents[0],
                green: primerColorTextPlaceholderComponents[1],
                blue: primerColorTextPlaceholderComponents[2],
                opacity: primerColorTextPlaceholderComponents[3]
            )
        }
        
        if let primerColorTextDisabledComponents = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorTextDisabled) {
            self.primerColorTextDisabled = Color(
                red: primerColorTextDisabledComponents[0],
                green: primerColorTextDisabledComponents[1],
                blue: primerColorTextDisabledComponents[2],
                opacity: primerColorTextDisabledComponents[3]
            )
        }
        
        if let primerColorTextNegativeComponents = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorTextNegative) {
            self.primerColorTextNegative = Color(
                red: primerColorTextNegativeComponents[0],
                green: primerColorTextNegativeComponents[1],
                blue: primerColorTextNegativeComponents[2],
                opacity: primerColorTextNegativeComponents[3]
            )
        }
        
        if let primerColorTextLinkComponents = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorTextLink) {
            self.primerColorTextLink = Color(
                red: primerColorTextLinkComponents[0],
                green: primerColorTextLinkComponents[1],
                blue: primerColorTextLinkComponents[2],
                opacity: primerColorTextLinkComponents[3]
            )
        }
        
        if let primerColorTextSecondaryComponents = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorTextSecondary) {
            self.primerColorTextSecondary = Color(
                red: primerColorTextSecondaryComponents[0],
                green: primerColorTextSecondaryComponents[1],
                blue: primerColorTextSecondaryComponents[2],
                opacity: primerColorTextSecondaryComponents[3]
            )
        }
        
        if let primerColorBorderOutlinedDefaultComponents = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorBorderOutlinedDefault) {
            self.primerColorBorderOutlinedDefault = Color(
                red: primerColorBorderOutlinedDefaultComponents[0],
                green: primerColorBorderOutlinedDefaultComponents[1],
                blue: primerColorBorderOutlinedDefaultComponents[2],
                opacity: primerColorBorderOutlinedDefaultComponents[3]
            )
        }
        
        if let primerColorBorderOutlinedHoverComponents = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorBorderOutlinedHover) {
            self.primerColorBorderOutlinedHover = Color(
                red: primerColorBorderOutlinedHoverComponents[0],
                green: primerColorBorderOutlinedHoverComponents[1],
                blue: primerColorBorderOutlinedHoverComponents[2],
                opacity: primerColorBorderOutlinedHoverComponents[3]
            )
        }
        
        if let primerColorBorderOutlinedActiveComponents = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorBorderOutlinedActive) {
            self.primerColorBorderOutlinedActive = Color(
                red: primerColorBorderOutlinedActiveComponents[0],
                green: primerColorBorderOutlinedActiveComponents[1],
                blue: primerColorBorderOutlinedActiveComponents[2],
                opacity: primerColorBorderOutlinedActiveComponents[3]
            )
        }
        
        if let primerColorBorderOutlinedFocusComponents = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorBorderOutlinedFocus) {
            self.primerColorBorderOutlinedFocus = Color(
                red: primerColorBorderOutlinedFocusComponents[0],
                green: primerColorBorderOutlinedFocusComponents[1],
                blue: primerColorBorderOutlinedFocusComponents[2],
                opacity: primerColorBorderOutlinedFocusComponents[3]
            )
        }
        
        if let primerColorBorderOutlinedDisabledComponents = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorBorderOutlinedDisabled) {
            self.primerColorBorderOutlinedDisabled = Color(
                red: primerColorBorderOutlinedDisabledComponents[0],
                green: primerColorBorderOutlinedDisabledComponents[1],
                blue: primerColorBorderOutlinedDisabledComponents[2],
                opacity: primerColorBorderOutlinedDisabledComponents[3]
            )
        }
        
        if let primerColorBorderOutlinedLoadingComponents = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorBorderOutlinedLoading) {
            self.primerColorBorderOutlinedLoading = Color(
                red: primerColorBorderOutlinedLoadingComponents[0],
                green: primerColorBorderOutlinedLoadingComponents[1],
                blue: primerColorBorderOutlinedLoadingComponents[2],
                opacity: primerColorBorderOutlinedLoadingComponents[3]
            )
        }
        
        if let primerColorBorderOutlinedSelectedComponents = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorBorderOutlinedSelected) {
            self.primerColorBorderOutlinedSelected = Color(
                red: primerColorBorderOutlinedSelectedComponents[0],
                green: primerColorBorderOutlinedSelectedComponents[1],
                blue: primerColorBorderOutlinedSelectedComponents[2],
                opacity: primerColorBorderOutlinedSelectedComponents[3]
            )
        }
        
        if let primerColorBorderOutlinedErrorComponents = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorBorderOutlinedError) {
            self.primerColorBorderOutlinedError = Color(
                red: primerColorBorderOutlinedErrorComponents[0],
                green: primerColorBorderOutlinedErrorComponents[1],
                blue: primerColorBorderOutlinedErrorComponents[2],
                opacity: primerColorBorderOutlinedErrorComponents[3]
            )
        }
        
        if let primerColorBorderTransparentDefaultComponents = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorBorderTransparentDefault) {
            self.primerColorBorderTransparentDefault = Color(
                red: primerColorBorderTransparentDefaultComponents[0],
                green: primerColorBorderTransparentDefaultComponents[1],
                blue: primerColorBorderTransparentDefaultComponents[2],
                opacity: primerColorBorderTransparentDefaultComponents[3]
            )
        }
        
        if let primerColorBorderTransparentHoverComponents = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorBorderTransparentHover) {
            self.primerColorBorderTransparentHover = Color(
                red: primerColorBorderTransparentHoverComponents[0],
                green: primerColorBorderTransparentHoverComponents[1],
                blue: primerColorBorderTransparentHoverComponents[2],
                opacity: primerColorBorderTransparentHoverComponents[3]
            )
        }
        
        if let primerColorBorderTransparentActiveComponents = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorBorderTransparentActive) {
            self.primerColorBorderTransparentActive = Color(
                red: primerColorBorderTransparentActiveComponents[0],
                green: primerColorBorderTransparentActiveComponents[1],
                blue: primerColorBorderTransparentActiveComponents[2],
                opacity: primerColorBorderTransparentActiveComponents[3]
            )
        }
        
        if let primerColorBorderTransparentFocusComponents = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorBorderTransparentFocus) {
            self.primerColorBorderTransparentFocus = Color(
                red: primerColorBorderTransparentFocusComponents[0],
                green: primerColorBorderTransparentFocusComponents[1],
                blue: primerColorBorderTransparentFocusComponents[2],
                opacity: primerColorBorderTransparentFocusComponents[3]
            )
        }
        
        if let primerColorBorderTransparentDisabledComponents = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorBorderTransparentDisabled) {
            self.primerColorBorderTransparentDisabled = Color(
                red: primerColorBorderTransparentDisabledComponents[0],
                green: primerColorBorderTransparentDisabledComponents[1],
                blue: primerColorBorderTransparentDisabledComponents[2],
                opacity: primerColorBorderTransparentDisabledComponents[3]
            )
        }
        
        if let primerColorBorderTransparentSelectedComponents = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorBorderTransparentSelected) {
            self.primerColorBorderTransparentSelected = Color(
                red: primerColorBorderTransparentSelectedComponents[0],
                green: primerColorBorderTransparentSelectedComponents[1],
                blue: primerColorBorderTransparentSelectedComponents[2],
                opacity: primerColorBorderTransparentSelectedComponents[3]
            )
        }
        
        if let primerColorIconPrimaryComponents = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorIconPrimary) {
            self.primerColorIconPrimary = Color(
                red: primerColorIconPrimaryComponents[0],
                green: primerColorIconPrimaryComponents[1],
                blue: primerColorIconPrimaryComponents[2],
                opacity: primerColorIconPrimaryComponents[3]
            )
        }
        
        if let primerColorIconDisabledComponents = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorIconDisabled) {
            self.primerColorIconDisabled = Color(
                red: primerColorIconDisabledComponents[0],
                green: primerColorIconDisabledComponents[1],
                blue: primerColorIconDisabledComponents[2],
                opacity: primerColorIconDisabledComponents[3]
            )
        }
        
        if let primerColorIconNegativeComponents = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorIconNegative) {
            self.primerColorIconNegative = Color(
                red: primerColorIconNegativeComponents[0],
                green: primerColorIconNegativeComponents[1],
                blue: primerColorIconNegativeComponents[2],
                opacity: primerColorIconNegativeComponents[3]
            )
        }
        
        if let primerColorIconPositiveComponents = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorIconPositive) {
            self.primerColorIconPositive = Color(
                red: primerColorIconPositiveComponents[0],
                green: primerColorIconPositiveComponents[1],
                blue: primerColorIconPositiveComponents[2],
                opacity: primerColorIconPositiveComponents[3]
            )
        }
        
        if let primerColorFocusComponents = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorFocus) {
            self.primerColorFocus = Color(
                red: primerColorFocusComponents[0],
                green: primerColorFocusComponents[1],
                blue: primerColorFocusComponents[2],
                opacity: primerColorFocusComponents[3]
            )
        }
        
        if let primerColorLoaderComponents = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorLoader) {
            self.primerColorLoader = Color(
                red: primerColorLoaderComponents[0],
                green: primerColorLoaderComponents[1],
                blue: primerColorLoaderComponents[2],
                opacity: primerColorLoaderComponents[3]
            )
        }
        
        if let primerColorGray100Components = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorGray100) {
            self.primerColorGray100 = Color(
                red: primerColorGray100Components[0],
                green: primerColorGray100Components[1],
                blue: primerColorGray100Components[2],
                opacity: primerColorGray100Components[3]
            )
        }
        
        if let primerColorGray200Components = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorGray200) {
            self.primerColorGray200 = Color(
                red: primerColorGray200Components[0],
                green: primerColorGray200Components[1],
                blue: primerColorGray200Components[2],
                opacity: primerColorGray200Components[3]
            )
        }
        
        if let primerColorGray300Components = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorGray300) {
            self.primerColorGray300 = Color(
                red: primerColorGray300Components[0],
                green: primerColorGray300Components[1],
                blue: primerColorGray300Components[2],
                opacity: primerColorGray300Components[3]
            )
        }
        
        if let primerColorGray400Components = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorGray400) {
            self.primerColorGray400 = Color(
                red: primerColorGray400Components[0],
                green: primerColorGray400Components[1],
                blue: primerColorGray400Components[2],
                opacity: primerColorGray400Components[3]
            )
        }
        
        if let primerColorGray500Components = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorGray500) {
            self.primerColorGray500 = Color(
                red: primerColorGray500Components[0],
                green: primerColorGray500Components[1],
                blue: primerColorGray500Components[2],
                opacity: primerColorGray500Components[3]
            )
        }
        
        if let primerColorGray600Components = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorGray600) {
            self.primerColorGray600 = Color(
                red: primerColorGray600Components[0],
                green: primerColorGray600Components[1],
                blue: primerColorGray600Components[2],
                opacity: primerColorGray600Components[3]
            )
        }
        
        if let primerColorGray900Components = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorGray900) {
            self.primerColorGray900 = Color(
                red: primerColorGray900Components[0],
                green: primerColorGray900Components[1],
                blue: primerColorGray900Components[2],
                opacity: primerColorGray900Components[3]
            )
        }
        
        if let primerColorGray000Components = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorGray000) {
            self.primerColorGray000 = Color(
                red: primerColorGray000Components[0],
                green: primerColorGray000Components[1],
                blue: primerColorGray000Components[2],
                opacity: primerColorGray000Components[3]
            )
        }
        
        if let primerColorGreen500Components = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorGreen500) {
            self.primerColorGreen500 = Color(
                red: primerColorGreen500Components[0],
                green: primerColorGreen500Components[1],
                blue: primerColorGreen500Components[2],
                opacity: primerColorGreen500Components[3]
            )
        }
        
        if let primerColorBrandComponents = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorBrand) {
            self.primerColorBrand = Color(
                red: primerColorBrandComponents[0],
                green: primerColorBrandComponents[1],
                blue: primerColorBrandComponents[2],
                opacity: primerColorBrandComponents[3]
            )
        }
        
        if let primerColorRed100Components = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorRed100) {
            self.primerColorRed100 = Color(
                red: primerColorRed100Components[0],
                green: primerColorRed100Components[1],
                blue: primerColorRed100Components[2],
                opacity: primerColorRed100Components[3]
            )
        }
        
        if let primerColorRed500Components = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorRed500) {
            self.primerColorRed500 = Color(
                red: primerColorRed500Components[0],
                green: primerColorRed500Components[1],
                blue: primerColorRed500Components[2],
                opacity: primerColorRed500Components[3]
            )
        }
        
        if let primerColorRed900Components = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorRed900) {
            self.primerColorRed900 = Color(
                red: primerColorRed900Components[0],
                green: primerColorRed900Components[1],
                blue: primerColorRed900Components[2],
                opacity: primerColorRed900Components[3]
            )
        }
        
        if let primerColorBlue500Components = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorBlue500) {
            self.primerColorBlue500 = Color(
                red: primerColorBlue500Components[0],
                green: primerColorBlue500Components[1],
                blue: primerColorBlue500Components[2],
                opacity: primerColorBlue500Components[3]
            )
        }
        
        if let primerColorBlue900Components = try container.decodeIfPresent([CGFloat].self, forKey: .primerColorBlue900) {
            self.primerColorBlue900 = Color(
                red: primerColorBlue900Components[0],
                green: primerColorBlue900Components[1],
                blue: primerColorBlue900Components[2],
                opacity: primerColorBlue900Components[3]
            )
        }
        self.primerRadiusMedium = try container.decodeIfPresent(CGFloat.self, forKey: .primerRadiusMedium)
        self.primerRadiusSmall = try container.decodeIfPresent(CGFloat.self, forKey: .primerRadiusSmall)
        self.primerRadiusLarge = try container.decodeIfPresent(CGFloat.self, forKey: .primerRadiusLarge)
        self.primerRadiusXsmall = try container.decodeIfPresent(CGFloat.self, forKey: .primerRadiusXsmall)
        self.primerRadiusBase = try container.decodeIfPresent(CGFloat.self, forKey: .primerRadiusBase)
        self.primerTypographyBrand = try container.decodeIfPresent(String.self, forKey: .primerTypographyBrand)
        self.primerTypographyTitleXlargeFont = try container.decodeIfPresent(String.self, forKey: .primerTypographyTitleXlargeFont)
        self.primerTypographyTitleXlargeLetterSpacing = try container.decodeIfPresent(CGFloat.self, forKey: .primerTypographyTitleXlargeLetterSpacing)
        self.primerTypographyTitleXlargeWeight = try container.decodeIfPresent(CGFloat.self, forKey: .primerTypographyTitleXlargeWeight)
        self.primerTypographyTitleXlargeSize = try container.decodeIfPresent(CGFloat.self, forKey: .primerTypographyTitleXlargeSize)
        self.primerTypographyTitleXlargeLineHeight = try container.decodeIfPresent(CGFloat.self, forKey: .primerTypographyTitleXlargeLineHeight)
        self.primerTypographyTitleLargeFont = try container.decodeIfPresent(String.self, forKey: .primerTypographyTitleLargeFont)
        self.primerTypographyTitleLargeLetterSpacing = try container.decodeIfPresent(CGFloat.self, forKey: .primerTypographyTitleLargeLetterSpacing)
        self.primerTypographyTitleLargeWeight = try container.decodeIfPresent(CGFloat.self, forKey: .primerTypographyTitleLargeWeight)
        self.primerTypographyTitleLargeSize = try container.decodeIfPresent(CGFloat.self, forKey: .primerTypographyTitleLargeSize)
        self.primerTypographyTitleLargeLineHeight = try container.decodeIfPresent(CGFloat.self, forKey: .primerTypographyTitleLargeLineHeight)
        self.primerTypographyBodyLargeFont = try container.decodeIfPresent(String.self, forKey: .primerTypographyBodyLargeFont)
        self.primerTypographyBodyLargeLetterSpacing = try container.decodeIfPresent(CGFloat.self, forKey: .primerTypographyBodyLargeLetterSpacing)
        self.primerTypographyBodyLargeWeight = try container.decodeIfPresent(CGFloat.self, forKey: .primerTypographyBodyLargeWeight)
        self.primerTypographyBodyLargeSize = try container.decodeIfPresent(CGFloat.self, forKey: .primerTypographyBodyLargeSize)
        self.primerTypographyBodyLargeLineHeight = try container.decodeIfPresent(CGFloat.self, forKey: .primerTypographyBodyLargeLineHeight)
        self.primerTypographyBodyMediumFont = try container.decodeIfPresent(String.self, forKey: .primerTypographyBodyMediumFont)
        self.primerTypographyBodyMediumLetterSpacing = try container.decodeIfPresent(CGFloat.self, forKey: .primerTypographyBodyMediumLetterSpacing)
        self.primerTypographyBodyMediumWeight = try container.decodeIfPresent(CGFloat.self, forKey: .primerTypographyBodyMediumWeight)
        self.primerTypographyBodyMediumSize = try container.decodeIfPresent(CGFloat.self, forKey: .primerTypographyBodyMediumSize)
        self.primerTypographyBodyMediumLineHeight = try container.decodeIfPresent(CGFloat.self, forKey: .primerTypographyBodyMediumLineHeight)
        self.primerTypographyBodySmallFont = try container.decodeIfPresent(String.self, forKey: .primerTypographyBodySmallFont)
        self.primerTypographyBodySmallLetterSpacing = try container.decodeIfPresent(CGFloat.self, forKey: .primerTypographyBodySmallLetterSpacing)
        self.primerTypographyBodySmallWeight = try container.decodeIfPresent(CGFloat.self, forKey: .primerTypographyBodySmallWeight)
        self.primerTypographyBodySmallSize = try container.decodeIfPresent(CGFloat.self, forKey: .primerTypographyBodySmallSize)
        self.primerTypographyBodySmallLineHeight = try container.decodeIfPresent(CGFloat.self, forKey: .primerTypographyBodySmallLineHeight)
        self.primerSpaceXxsmall = try container.decodeIfPresent(CGFloat.self, forKey: .primerSpaceXxsmall)
        self.primerSpaceXsmall = try container.decodeIfPresent(CGFloat.self, forKey: .primerSpaceXsmall)
        self.primerSpaceSmall = try container.decodeIfPresent(CGFloat.self, forKey: .primerSpaceSmall)
        self.primerSpaceMedium = try container.decodeIfPresent(CGFloat.self, forKey: .primerSpaceMedium)
        self.primerSpaceLarge = try container.decodeIfPresent(CGFloat.self, forKey: .primerSpaceLarge)
        self.primerSpaceXlarge = try container.decodeIfPresent(CGFloat.self, forKey: .primerSpaceXlarge)
        self.primerSpaceBase = try container.decodeIfPresent(CGFloat.self, forKey: .primerSpaceBase)
        self.primerSizeSmall = try container.decodeIfPresent(CGFloat.self, forKey: .primerSizeSmall)
        self.primerSizeMedium = try container.decodeIfPresent(CGFloat.self, forKey: .primerSizeMedium)
        self.primerSizeLarge = try container.decodeIfPresent(CGFloat.self, forKey: .primerSizeLarge)
        self.primerSizeXlarge = try container.decodeIfPresent(CGFloat.self, forKey: .primerSizeXlarge)
        self.primerSizeXxlarge = try container.decodeIfPresent(CGFloat.self, forKey: .primerSizeXxlarge)
        self.primerSizeXxxlarge = try container.decodeIfPresent(CGFloat.self, forKey: .primerSizeXxxlarge)
        self.primerSizeBase = try container.decodeIfPresent(CGFloat.self, forKey: .primerSizeBase)
    }
}
// swiftlint:enable all
