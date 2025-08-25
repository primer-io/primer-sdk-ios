//
//  PrimerStackVIew.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

final class PrimerStackView: UIStackView {}

extension PrimerStackView {

    func addBackground(color: UIColor) {

        if #available(iOS 14.0, *) {

            backgroundColor = color

        } else {

            // Fallback to manually adding
            // background view

            let subView = UIView(frame: bounds)
            subView.backgroundColor = color
            subView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            insertSubview(subView, at: 0)
        }
    }
}
