//
//  UIKeyboardType.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

extension UIKeyboardType {
    init(_ keyboardType: KeyboardType) {
        switch keyboardType {
        case "numberPad": self = .numberPad
        case "emailAddress": self = .emailAddress
        case "phone": self = .phonePad
        case "url": self = .URL
        default: self = .default
        }
    }
}
