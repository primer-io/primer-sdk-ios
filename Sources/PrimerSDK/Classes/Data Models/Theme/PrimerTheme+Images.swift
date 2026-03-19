//
//  PrimerTheme+Images.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerCore
import PrimerFoundation
import UIKit

extension PrimerTheme {

    final class BaseImage {

        var colored: UIImage?
        var light: UIImage?
        var dark: UIImage?

        init?(colored: UIImage?, light: UIImage?, dark: UIImage?) {
            self.colored = colored
            self.light = light
            self.dark = dark

            if self.colored == nil, self.light == nil, self.dark == nil {
                return nil
            }
        }
    }

}
