//
//  NibView.swift
//  PrimerCoreKit
//
//  Created by Evangelos Pittas on 22/1/20.
//  Copyright © 2020 Primer. All rights reserved.
//

import UIKit

public class PrimerNibView: UIView {
    
    internal var view: UIView!
    
    override internal init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required internal init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    internal func xibSetup() {
        backgroundColor = UIColor.clear
        view = loadNib()
        // use bounds not frame or it'll be offset
        view.frame = bounds
        // Adding custom subview on top of our view
        addSubview(view)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[childView]|",
                                                      options: [],
                                                      metrics: nil,
                                                      views: ["childView": view]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[childView]|",
                                                      options: [],
                                                      metrics: nil,
                                                      views: ["childView": view]))
    }
}

internal extension UIView {
    /** Loads instance from nib with the same name. */
    func loadNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        var nibName = type(of: self).description().components(separatedBy: ".").last!
        
        if nibName == "PrimerCardNumberField" {
            nibName = "PrimerPCITextField"
        } else if nibName == "PrimerExpiryDateField" {
            nibName = "PrimerPCITextField"
        } else if nibName == "PrimerCVVField" {
            nibName = "PrimerPCITextField"
        } else if nibName == "PrimerNameField" {
            nibName = "PrimerPCITextField"
        }
        
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as! UIView
    }
}
