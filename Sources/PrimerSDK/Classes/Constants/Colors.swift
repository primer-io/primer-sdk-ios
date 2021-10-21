// MARK: Light

import UIKit

internal struct Colors {
    
    private static let lightModeBlack = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1)
    private static let lightModeWhite = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1)
    private static let lightModeGray = UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 1)
    private static let lightModeLightGray = UIColor(red: 229/255, green: 229/255, blue: 234/255, alpha: 1)
    private static let lightModeRed = UIColor(red: 255/255, green: 59/255, blue: 48/255, alpha: 1)
    private static let lightModeBlue = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1)
    private static let lightModeYellow = UIColor(red: 255/255, green: 204/255, blue: 0/255, alpha: 1)
    private static let lightModeGreen = UIColor(red: 52/255, green: 199/255, blue: 89/255, alpha: 1)

    private static let darkModeBlack = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1)
    private static let darkModeWhite = UIColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1)
    private static let darkModeGray = UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 1)
    private static let darkModeLightGray = UIColor(red: 58/255, green: 58/255, blue: 60/255, alpha: 1)
    private static let darkModeRed = UIColor(red: 255/255, green: 69/255, blue: 58/255, alpha: 1)
    private static let darkModeBlue = UIColor(red: 10/255, green: 132/255, blue: 255/255, alpha: 1)
    private static let darkModeYellow = UIColor(red: 255/255, green: 214/255, blue: 10/255, alpha: 1)
    private static let darkModeGreen = UIColor(red: 50/255, green: 215/255, blue: 75/255, alpha: 1)
    
    // MARK: defaults
    static let Black = UIColor.dynamic(lightMode: lightModeBlack, darkMode: darkModeBlack)
    static let White = UIColor.dynamic(lightMode: lightModeWhite, darkMode: darkModeWhite)
    static let Gray = UIColor.dynamic(lightMode: lightModeGray, darkMode: darkModeGray)
    static let LightGray = UIColor.dynamic(lightMode: lightModeLightGray, darkMode: darkModeLightGray)
    static let Red = UIColor.dynamic(lightMode: lightModeRed, darkMode: darkModeRed)
    static let Blue = UIColor.dynamic(lightMode: lightModeBlue, darkMode: darkModeBlue)
    static let Yellow = UIColor.dynamic(lightMode: lightModeYellow, darkMode: darkModeYellow)
    static let Green = UIColor.dynamic(lightMode: lightModeGreen, darkMode: darkModeGreen)
    
    // MARK: special cases
    static let KlarnaPink = UIColor(red: 1, green: 0.702, blue: 0.78, alpha: 1)
}
