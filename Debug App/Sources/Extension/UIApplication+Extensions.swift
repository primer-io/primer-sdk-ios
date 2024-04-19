//
//  UIApplication+Extensions.swift
//  Debug App
//
//  Created by Jack Newcombe on 19/04/2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import UIKit

extension UIApplication {
    var windows: [UIWindow] {
        let windowScene = self.connectedScenes.compactMap{ $0 as? UIWindowScene }.first
        guard let windows = windowScene?.windows else {
            return []
        }
        return windows
    }

    var keyWindow: UIWindow? {
        return windows.first
    }
}
