// swiftlint:disable all
import SwiftUI

// This class is generated automatically by Style Dictionary.
// It represents the design tokens for the Dark theme.
internal class DesignTokensDark: Decodable {
    public var primerColorGray100: Color? = Color(red: 0.161, green: 0.161, blue: 0.161, opacity: 1)
    public var primerColorGray200: Color? = Color(red: 0.259, green: 0.259, blue: 0.259, opacity: 1)
    public var primerColorGray300: Color? = Color(red: 0.341, green: 0.341, blue: 0.341, opacity: 1)
    public var primerColorGray400: Color? = Color(red: 0.522, green: 0.522, blue: 0.522, opacity: 1)
    public var primerColorGray500: Color? = Color(red: 0.463, green: 0.459, blue: 0.467, opacity: 1)
    public var primerColorGray600: Color? = Color(red: 0.780, green: 0.780, blue: 0.780, opacity: 1)
    public var primerColorGray900: Color? = Color(red: 0.937, green: 0.937, blue: 0.937, opacity: 1)
    public var primerColorGray000: Color? = Color(red: 0.090, green: 0.086, blue: 0.098, opacity: 1)
    public var primerColorGreen500: Color? = Color(red: 0.153, green: 0.694, blue: 0.490, opacity: 1)
    public var primerColorBrand: Color? = Color(red: 0.184, green: 0.596, blue: 1.000, opacity: 1)
    public var primerColorRed100: Color? = Color(red: 0.196, green: 0.110, blue: 0.125, opacity: 1)
    public var primerColorRed500: Color? = Color(red: 0.894, green: 0.427, blue: 0.439, opacity: 1)
    public var primerColorRed900: Color? = Color(red: 0.965, green: 0.749, blue: 0.749, opacity: 1)
    public var primerColorBlue500: Color? = Color(red: 0.247, green: 0.576, blue: 0.894, opacity: 1)
    public var primerColorBlue900: Color? = Color(red: 0.290, green: 0.682, blue: 1.000, opacity: 1)

    enum CodingKeys: String, CodingKey {
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
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
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
    }
}
// swiftlint:enable all
