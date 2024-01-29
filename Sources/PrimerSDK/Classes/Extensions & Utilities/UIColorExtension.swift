//
//  UIColorExtension.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 2/8/21.
//

import UIKit

internal class PrimerColor: UIColor {

    static func dynamic(lightMode: PrimerColor, darkMode: PrimerColor) -> PrimerColor {
        guard #available(iOS 13.0, *) else { return lightMode }

        return PrimerColor { (traitCollection) -> UIColor in
            return traitCollection.userInterfaceStyle == .light ? lightMode : darkMode
        }
    }
}

internal extension PrimerColor {

    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")

        self.init(
            red: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: 1.0
        )
    }

    convenience init(rgba: Int) {
        self.init(
            red: CGFloat((rgba >> 24) & 0xFF),
            green: CGFloat((rgba >> 16) & 0xFF),
            blue: CGFloat((rgba >> 8) & 0xFF),
            alpha: CGFloat(rgba & 0xFF)
        )
    }

    static func rgb(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8 = 255) -> PrimerColor {
        return PrimerColor(
            red: CGFloat(red) / 255,
            green: CGFloat(green) / 255,
            blue: CGFloat(blue) / 255,
            alpha: CGFloat(alpha) / 255
        )
    }

    convenience init?(hex: String) {
        let red, green, blue, alpha: CGFloat

        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            var hexColor = String(hex[start...])

            if hexColor.count == 6 {
                hexColor += "ff"
            }

            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    red = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    green = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    blue = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    alpha = CGFloat(hexNumber & 0x000000ff) / 255

                    self.init(red: red, green: green, blue: blue, alpha: alpha)
                    return
                }
            }
        }

        return nil
    }

    static var random: PrimerColor {
        return PrimerColor(red: Int.random(in: 0...255), green: Int.random(in: 0...255), blue: Int.random(in: 0...255))
    }

    var hexString: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let rgb: Int = (Int)(red*255)<<16 | (Int)(green*255)<<8 | (Int)(blue*255)<<0
        return String(format: "#%06x", rgb)
    }
}

public extension UIColor {

    // MARK: - Gray

    static let gray100  = #colorLiteral(red: 0.9606924653, green: 0.9608384967, blue: 0.9606702924, alpha: 1)
    static let gray200  = #colorLiteral(red: 0.9214878678, green: 0.9216204286, blue: 0.9214589, alpha: 1)
    static let gray300  = #colorLiteral(red: 0.8548267484, green: 0.8549502492, blue: 0.8547996879, alpha: 1)
    static let gray400  = #colorLiteral(red: 0.705819428, green: 0.7059227824, blue: 0.7057968378, alpha: 1)
    static let gray500  = #colorLiteral(red: 0.5607333183, green: 0.5608169436, blue: 0.5607150793, alpha: 1)
    static let gray600  = #colorLiteral(red: 0.4117260277, green: 0.4117894769, blue: 0.4117121696, alpha: 1)
    static let gray700  = #colorLiteral(red: 0.2666399777, green: 0.2666836977, blue: 0.2666304708, alpha: 1)
}
