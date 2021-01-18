//
//  ImageName.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 29/12/2020.
//

import UIKit

enum ImageName: String {
    case
        amex,
        appleIcon,
        back,
        discover,
        masterCard,
        visa,
        creditCard,
        check,
        success,
        delete,
        paypal
    
    var image: UIImage? {
        let frameworkBundle = Bundle(for: Primer.self)
        let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("PrimerSDK.bundle")
        let resourceBundle = Bundle(url: bundleURL!)
        guard let image = UIImage(named: rawValue, in: resourceBundle, compatibleWith: nil) else {
            return nil
        }
        print("🌃 image:", image)
        return image
    }
}
