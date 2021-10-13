// MARK: Light

import UIKit
private let Black = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1)
private let White = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1)
private let Gray = UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 1)
private let LightGray = UIColor(red: 229/255, green: 229/255, blue: 234/255, alpha: 1)
private let Red = UIColor(red: 255/255, green: 59/255, blue: 48/255, alpha: 1)
private let Blue = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1)
private let Yellow = UIColor(red: 255/255, green: 204/255, blue: 0/255, alpha: 1)
private let Green = UIColor(red: 52/255, green: 199/255, blue: 89/255, alpha: 1)

// MARK: Dark
private let DarkModeBlack = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1)
private let DarkModeWhite = UIColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1)
private let DarkModeGray = UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 1)
private let DarkModeLightGray = UIColor(red: 58/255, green: 58/255, blue: 60/255, alpha: 1)
private let DarkModeRed = UIColor(red: 255/255, green: 69/255, blue: 58/255, alpha: 1)
private let DarkModeBlue = UIColor(red: 10/255, green: 132/255, blue: 255/255, alpha: 1)
private let DarkModeYellow = UIColor(red: 255/255, green: 214/255, blue: 10/255, alpha: 1)
private let DarkModeGreen = UIColor(red: 50/255, green: 215/255, blue: 75/255, alpha: 1)

internal struct Colors {
    static let Background = UIColor.white
    
    struct Text {
        static let Default = UIColor.primer(lightMode: Black, darkMode: DarkModeBlack)
        static let Title = UIColor.primer(lightMode: Black, darkMode: DarkModeBlack)
        static let Subtitle = UIColor.primer(lightMode: Gray, darkMode: Gray)
        static let AmountLabel = UIColor.primer(lightMode: Black, darkMode: DarkModeBlack)
        static let System = UIColor.primer(lightMode: Blue, darkMode: DarkModeBlue)
        static let Error = UIColor.primer(lightMode: Red, darkMode: Red)
    }

    struct Buttons {
        
        struct Main {
            static let Default = UIColor.primer(lightMode: Blue, darkMode: DarkModeBlue)
            static let Disabled = UIColor.primer(lightMode: LightGray, darkMode: DarkModeLightGray)
            static let Selected = UIColor.primer(lightMode: Blue, darkMode: DarkModeBlue)
            
            struct Border {
                static let Default = UIColor.primer(lightMode: Blue, darkMode: DarkModeBlue)
                static let Disabled = UIColor.primer(lightMode: LightGray, darkMode: DarkModeLightGray)
                static let Selected = UIColor.primer(lightMode: Blue, darkMode: DarkModeBlue)
            }
            
            struct Text {
                static let Enabled = UIColor.primer(lightMode: White, darkMode: DarkModeWhite)
                static let Disabled = UIColor.primer(lightMode: White, darkMode: DarkModeWhite)
            }
        }
        
        struct PaymentMethod {
            static let Default = UIColor.primer(lightMode: White, darkMode: DarkModeWhite)
            static let Disabled = UIColor.primer(lightMode: LightGray, darkMode: DarkModeLightGray)
            static let Selected = UIColor.primer(lightMode: Blue, darkMode: DarkModeBlue)
            
            struct Border {
                static let Default = UIColor.primer(lightMode: Gray, darkMode: Gray)
                static let Disabled = UIColor.primer(lightMode: LightGray, darkMode: DarkModeLightGray)
                static let Selected = UIColor.primer(lightMode: Blue, darkMode: DarkModeBlue)
            }
            
            struct Text {
                static let Enabled = UIColor.primer(lightMode: Black, darkMode: DarkModeBlack)
                static let Disabled = UIColor.primer(lightMode: Gray, darkMode: Gray)
            }
        }
    }
    
    struct Input {
        static let Background = UIColor.primer(lightMode: White, darkMode: DarkModeWhite)
        static let Text = UIColor.primer(lightMode: Black, darkMode: DarkModeBlack)
        static let HintText = UIColor.primer(lightMode: Gray, darkMode: Gray)
        static let ErrorText = UIColor.primer(lightMode: Red, darkMode: Red)
        
        struct Border {
            static let Default = UIColor.primer(lightMode: Black, darkMode: DarkModeBlack)
            static let Disabled = UIColor.primer(lightMode: LightGray, darkMode: DarkModeLightGray)
            static let Selected = UIColor.primer(lightMode: Blue, darkMode: DarkModeBlue)
        }
    }
}
