//
//  UIStackViewExtensions.swift
//  Debug App
//
//  Created by Evangelos Pittas on 8/2/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import UIKit

extension UIStackView {
    
    func removeAllArrangedSubviews() {
        for arrangedSubview in arrangedSubviews {
            removeArrangedSubview(arrangedSubview)
            arrangedSubview.removeFromSuperview()
        }
    }
}
