//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//


#if canImport(UIKit)

import UIKit

internal class PrimerStackView: UIStackView {}

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

#endif

