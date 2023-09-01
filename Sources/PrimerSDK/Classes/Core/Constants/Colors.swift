// MARK: Light



import UIKit

public struct PrimerColors {
    
    private static let lightModeBlack = PrimerColor.rgb(red: 0, green: 0, blue: 0)
    private static let lightModeWhite = PrimerColor.rgb(red: 255, green: 255, blue: 255)
    private static let lightModeGray = PrimerColor.rgb(red: 142, green: 142, blue: 147)
    private static let lightModeLightGray = PrimerColor.rgb(red: 229, green: 229, blue: 234)
    private static let lightModeRed = PrimerColor.rgb(red: 255, green: 59, blue: 48)
    private static let lightModeBlue = PrimerColor.rgb(red: 0, green: 122, blue: 255)
    private static let lightModeYellow = PrimerColor.rgb(red: 255, green: 204, blue: 0)
    private static let lightModeGreen = PrimerColor.rgb(red: 52, green: 199, blue: 89)

    private static let darkModeBlack = PrimerColor.rgb(red: 255, green: 255, blue: 255)
    private static let darkModeWhite = PrimerColor.rgb(red: 28, green: 28, blue: 30)
    private static let darkModeGray = PrimerColor.rgb(red: 142, green: 142, blue: 147)
    private static let darkModeLightGray = PrimerColor.rgb(red: 58, green: 58, blue: 60)
    private static let darkModeRed = PrimerColor.rgb(red: 255, green: 69, blue: 58)
    private static let darkModeBlue = PrimerColor.rgb(red: 10, green: 132, blue: 255)
    private static let darkModeYellow = PrimerColor.rgb(red: 255, green: 214, blue: 10)
    private static let darkModeGreen = PrimerColor.rgb(red: 50, green: 215, blue: 75)
    
    // MARK: defaults
    public static let black: UIColor = PrimerColor.dynamic(lightMode: lightModeBlack, darkMode: darkModeBlack)
    public static let white: UIColor = PrimerColor.dynamic(lightMode: lightModeWhite, darkMode: darkModeWhite)
    public static let gray: UIColor = PrimerColor.dynamic(lightMode: lightModeGray, darkMode: darkModeGray)
    public static let lightGray: UIColor = PrimerColor.dynamic(lightMode: lightModeLightGray, darkMode: darkModeLightGray)
    public static let red: UIColor = PrimerColor.dynamic(lightMode: lightModeRed, darkMode: darkModeRed)
    public static let blue: UIColor = PrimerColor.dynamic(lightMode: lightModeBlue, darkMode: darkModeBlue)
    public static let yellow: UIColor = PrimerColor.dynamic(lightMode: lightModeYellow, darkMode: darkModeYellow)
    public static let green: UIColor = PrimerColor.dynamic(lightMode: lightModeGreen, darkMode: darkModeGreen)
    
    // MARK: special cases
    static let klarnaPink = UIColor(red: 1, green: 0.702, blue: 0.78, alpha: 1)
    static let blurredBackground = UIColor.black.withAlphaComponent(0.4)
}


