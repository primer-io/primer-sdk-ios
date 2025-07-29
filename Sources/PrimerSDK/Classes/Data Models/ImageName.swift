//
//  ImageName.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

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
