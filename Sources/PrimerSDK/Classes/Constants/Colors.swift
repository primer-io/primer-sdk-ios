// MARK: Light

import UIKit
private let black = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1)
private let white = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1)
private let gray = UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 1)
private let lightGray = UIColor(red: 229/255, green: 229/255, blue: 234/255, alpha: 1)
private let red = UIColor(red: 255/255, green: 59/255, blue: 48/255, alpha: 1)
private let blue = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1)
private let yellow = UIColor(red: 255/255, green: 204/255, blue: 0/255, alpha: 1)
private let green = UIColor(red: 52/255, green: 199/255, blue: 89/255, alpha: 1)

// MARK: Dark
private let darkModeBlack = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1)
private let darkModeWhite = UIColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1)
private let darkModeGray = UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 1)
private let darkModeLightGray = UIColor(red: 58/255, green: 58/255, blue: 60/255, alpha: 1)
private let darkModeRed = UIColor(red: 255/255, green: 69/255, blue: 58/255, alpha: 1)
private let darkModeBlue = UIColor(red: 10/255, green: 132/255, blue: 255/255, alpha: 1)
private let darkModeYellow = UIColor(red: 255/255, green: 214/255, blue: 10/255, alpha: 1)
private let darkModeGreen = UIColor(red: 50/255, green: 215/255, blue: 75/255, alpha: 1)

internal struct Colors {
    static let Background = UIColor.white
    
    struct Text {
        static let Default = UIColor.primer(lightMode: black, darkMode: darkModeBlack)
        static let Title = UIColor.primer(lightMode: black, darkMode: darkModeBlack)
        static let Subtitle = UIColor.primer(lightMode: gray, darkMode: gray)
        static let AmountLabel = UIColor.primer(lightMode: black, darkMode: darkModeBlack)
        static let System = UIColor.primer(lightMode: blue, darkMode: darkModeBlue)
        static let Error = UIColor.primer(lightMode: red, darkMode: red)
    }

    struct Buttons {

        // Main
        static let MainDefault = UIColor.primer(lightMode: blue, darkMode: darkModeBlue)
        static let MainDisabled = UIColor.primer(lightMode: lightGray, darkMode: darkModeLightGray)
        static let MainSelected = UIColor.primer(lightMode: blue, darkMode: darkModeBlue)
        static let MainBorderDefault = UIColor.primer(lightMode: blue, darkMode: darkModeBlue)
        static let MainBorderDisabled = UIColor.primer(lightMode: lightGray, darkMode: darkModeLightGray)
        static let MainBorderSelected = UIColor.primer(lightMode: blue, darkMode: darkModeBlue)
        static let MainTextEnabled = UIColor.primer(lightMode: white, darkMode: darkModeWhite)
        static let MainTextDisabled = UIColor.primer(lightMode: white, darkMode: darkModeWhite)

        // Payment Method
        static let PaymentMethodDefault = UIColor.primer(lightMode: white, darkMode: darkModeWhite)
        static let PaymentMethodDisabled = UIColor.primer(lightMode: lightGray, darkMode: darkModeLightGray)
        static let PaymentMethodSelected = UIColor.primer(lightMode: blue, darkMode: darkModeBlue)
        static let PaymentMethodBorderDefault = UIColor.primer(lightMode: gray, darkMode: gray)
        static let PaymentMethodBorderDisabled = UIColor.primer(lightMode: lightGray, darkMode: darkModeLightGray)
        static let PaymentMethodBorderSelected = UIColor.primer(lightMode: blue, darkMode: darkModeBlue)
        static let PaymentMethodTextEnabled = UIColor.primer(lightMode: black, darkMode: darkModeBlack)
        static let PaymentMethodTextDisabled = UIColor.primer(lightMode: gray, darkMode: gray)
        
        // Klarna
        static let KlarnaDefault = UIColor(red: 1, green: 0.702, blue: 0.78, alpha: 1)
        static let KlarnaTextDefault = UIColor.primer(lightMode: black, darkMode: darkModeBlack)
    }

    struct Input {
        static let Background = UIColor.primer(lightMode: white, darkMode: darkModeWhite)
        static let Text = UIColor.primer(lightMode: black, darkMode: darkModeBlack)
        static let HintText = UIColor.primer(lightMode: gray, darkMode: gray)
        static let ErrorText = UIColor.primer(lightMode: red, darkMode: red)
        static let BorderDefault = UIColor.primer(lightMode: black, darkMode: darkModeBlack)
        static let BorderDisabled = UIColor.primer(lightMode: lightGray, darkMode: darkModeLightGray)
        static let BorderSelected = UIColor.primer(lightMode: blue, darkMode: darkModeBlue)
    }
}
