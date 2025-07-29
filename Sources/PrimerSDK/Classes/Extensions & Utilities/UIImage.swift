//
//  UIImage.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit.UIImage

extension UIImage {
    convenience init?(primerResource: String) {
        self.init(named: primerResource, in: .primerResources, compatibleWith: nil)
    }
}
