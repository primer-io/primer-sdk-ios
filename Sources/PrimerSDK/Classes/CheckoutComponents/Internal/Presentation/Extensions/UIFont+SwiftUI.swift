//
//  UIFont+SwiftUI.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 26.6.25.
//

import SwiftUI
import UIKit

/// Extension to convert SwiftUI Font to UIFont with proper iOS version compatibility
@available(iOS 15.0, *)
internal extension UIFont {
    /// Creates a UIFont from a SwiftUI Font with proper iOS version handling
    convenience init(_ font: Font) {
        // Handle all font cases
        // Note: Size is 0 to use the default size from the font descriptor,
        // which preserves the Dynamic Type scaling from the text style
        switch font {
        case .title2:
            self.init(descriptor: UIFont.preferredFont(forTextStyle: .title2).fontDescriptor, size: 0)
        case .title3:
            self.init(descriptor: UIFont.preferredFont(forTextStyle: .title3).fontDescriptor, size: 0)
        case .caption2:
            self.init(descriptor: UIFont.preferredFont(forTextStyle: .caption2).fontDescriptor, size: 0)
        case .largeTitle:
            self.init(descriptor: UIFont.preferredFont(forTextStyle: .largeTitle).fontDescriptor, size: 0)
        case .title:
            self.init(descriptor: UIFont.preferredFont(forTextStyle: .title1).fontDescriptor, size: 0)
        case .headline:
            self.init(descriptor: UIFont.preferredFont(forTextStyle: .headline).fontDescriptor, size: 0)
        case .subheadline:
            self.init(descriptor: UIFont.preferredFont(forTextStyle: .subheadline).fontDescriptor, size: 0)
        case .body:
            self.init(descriptor: UIFont.preferredFont(forTextStyle: .body).fontDescriptor, size: 0)
        case .callout:
            self.init(descriptor: UIFont.preferredFont(forTextStyle: .callout).fontDescriptor, size: 0)
        case .footnote:
            self.init(descriptor: UIFont.preferredFont(forTextStyle: .footnote).fontDescriptor, size: 0)
        case .caption:
            self.init(descriptor: UIFont.preferredFont(forTextStyle: .caption1).fontDescriptor, size: 0)
        default:
            // Fallback for newer cases on older iOS or custom fonts
            // Try Inter first (design system preference), then fall back to system
            if let interFont = UIFont(name: "Inter", size: 16) {
                self.init(descriptor: interFont.fontDescriptor, size: 16)
            } else {
                self.init(descriptor: UIFont.systemFont(ofSize: 16, weight: .regular).fontDescriptor, size: 16)
            }
        }
    }
}
