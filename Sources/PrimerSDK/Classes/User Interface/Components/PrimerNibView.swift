//
//  PrimerNibView.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

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
                                                      views: ["childView": view as UIView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[childView]|",
                                                      options: [],
                                                      metrics: nil,
                                                      views: ["childView": view as UIView]))
    }

    /** Loads instance from nib with the same name. */

    func loadNib() -> UIView? {
        let bundle = Bundle.primerResources
        let nib = UINib(nibName: className, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
}
