//
//  UIStackView+Background.swift
//  PrimerSDK
//
//  Copyright © 2022 Primer API ltd. All rights reserved.
//

import Foundation

extension UIStackView {
    
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
