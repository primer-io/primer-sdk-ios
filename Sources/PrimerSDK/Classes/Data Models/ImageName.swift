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
        achBank,
        camera,
        error,
        klarna,
        mobile

    public var image: UIImage? { UIImage(primerResource: rawValue) }
}
