

import UIKit

internal class BorderTheme {
    let colorStates: StatefulColor
    let width: CGFloat
    
    init(colorStates: StatefulColor, width: CGFloat) {
        self.colorStates = colorStates
        self.width = width
    }

    func color(for state: ColorState) -> UIColor {
        return colorStates.color(for: state)
    }
}


