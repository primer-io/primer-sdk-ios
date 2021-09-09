//
//  ImageName.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 29/12/2020.
//

#if canImport(UIKit)

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
        genericCard,
        check,
        check2,
        success,
        delete,
        paypal,
        paypal2,
        paypal3,
        forwardDark,
        lock,
        rightArrow,
        bank,
        camera,
        error,
        klarna,
        mobile

    public var image: UIImage? {
        guard let image = UIImage(named: rawValue, in: Bundle.primerResources, compatibleWith: nil) else {
            return nil
        }
        return image
    }
}

#endif
