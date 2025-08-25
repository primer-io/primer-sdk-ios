//
//  UIApplication+Extensions.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

extension UIApplication {
    var windows: [UIWindow] {
        let windowScene = self.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        guard let windows = windowScene?.windows else {
            return []
        }
        return windows
    }

    var keyWindow: UIWindow? {
        return windows.first
    }
}
