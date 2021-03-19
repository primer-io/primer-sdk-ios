//
//  SingleCardIconComponent.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 04/01/2021.
//

import UIKit

// FIXME: Unused?
class SingleCardIconComponent: UIView {
    
    let iconView: UIImageView
    
    init(frame: CGRect, iconName: String) {
        iconView = UIImageView(image: UIImage(named: iconName))
        super.init(frame: frame)
        addSubview(iconView)
        iconView.frame = CGRect(x: 4, y: 0, width: 30, height: 20)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
