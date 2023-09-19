//
//  PrimerNibView.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 29/6/21.
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
    
    /** Loads instance from nib with the same name. */
    
    func loadNib() -> UIView {
        let bundle = Bundle.primerResources
        let nib = UINib(nibName: className, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as! UIView
    }
}


