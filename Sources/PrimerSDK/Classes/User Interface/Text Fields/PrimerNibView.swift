//
//  PrimerNibView.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 29/6/21.
//

#if canImport(UIKit)

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

internal extension PrimerNibView {
    /** Loads instance from nib with the same name. */
    func loadNib() -> UIView {
        let bundle = Bundle.primerResources
        var nibName = type(of: self).description().components(separatedBy: ".").last!
        
        if nibName == "PrimerCardNumberFieldView" {
            nibName = "PrimerTextFieldView"
        } else if nibName == "PrimerExpiryDateFieldView" {
            nibName = "PrimerTextFieldView"
        } else if nibName == "PrimerCVVFieldView" {
            nibName = "PrimerTextFieldView"
        } else if nibName == "PrimerCardholderNameFieldView" {
           nibName = "PrimerTextFieldView"
        } else if nibName == "PrimerGenericFieldView" {
            nibName = "PrimerTextFieldView"
        }
        
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as! UIView
    }
}

#endif
