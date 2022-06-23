#if canImport(UIKit)

import UIKit

public struct PrimerDimensions {
    
    public static let cornerRadius: CGFloat = 0.0
    public static let safeArea: CGFloat = 10.0
    public static let zero: CGFloat = CGFloat.zero
    
    public struct StackViewSpacing {
        public static let `default`: CGFloat = 16.0
    }
    
    public struct Component {
        public static let cornerRadius: CGFloat = 4.0
        public static let borderWidth: CGFloat = 1.6
    }

    public struct Font {
        public static let title = 20
        public static let subtitle = 10
        public static let amountLabel = 24
        public static let body = 14
        public static let system = 12
        public static let error = 10
        public static let buttonLabel = 14
    }
}

#endif
