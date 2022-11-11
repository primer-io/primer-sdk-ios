//
//  UIFontExtension.swift
//  PrimerSDK
//
//  Created by Evangelos on 11/11/22.
//

#if canImport(UIKit)

internal extension UIFont.Weight {
    
    init(weight: CGFloat) {
        if weight < 150 {
            self = .ultraLight
        } else if weight < 250 {
            self = .thin
        } else if weight < 350 {
            self = .light
        } else if weight < 450 {
            self = .regular
        } else if weight < 550 {
            self = .medium
        } else if weight < 650 {
            self = .semibold
        } else if weight < 750 {
            self = .bold
        } else if weight < 850 {
            self = .heavy
        } else {
            self = .black
        }
    }
}

#endif
