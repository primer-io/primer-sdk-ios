//
//  ImageName.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 29/12/2020.
//

import UIKit

public enum ImageName: String {
    case
        amex,
        appleIcon,
        back,
        discover,
        masterCard,
        visa,
        creditCard,
        check,
        check2,
        success,
        delete,
        paypal,
        paypal2,
        paypal3,
        forwardDark,
        lock,
        rightArrow
    
    public var image: UIImage? {
        let frameworkBundle = Bundle(for: Primer.self)
        let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("PrimerSDK.bundle")
        let resourceBundle = Bundle(url: bundleURL!)
        guard let image = UIImage(named: rawValue, in: resourceBundle, compatibleWith: nil) else {
            return nil
        }
        return image
    }
}
