//
//  PrimerImage.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 20/10/21.
//

import UIKit

internal enum PrimerImage {

    case amexCardIcon,
         appleIcon,
         backIcon,
         bankcontactCardIcon,
         bankIcon,
         backIconRTL,
         cameraIcon,
         checkmarkIcon,
         creditCardIcon,
         deleteIcon,
         discoverCardIcon,
         errorIcon,
         forwardArrowIcon,
         genericCardIcon,
         jcbCardIcon,
         klarnaLogo,
         lockIcon,
         masterCardIcon,
         mobileIcon,
         payPalLogoCopy,
         payPalLogo,
         rightArrowIcon,
         successIcon,
         visaIcon

    var image: UIImage? {
        switch self {
        case .amexCardIcon:
            return UIImage(named: "amex", in: Bundle.primerResources, compatibleWith: nil)
        case .appleIcon:
            return UIImage(named: "appleIcon", in: Bundle.primerResources, compatibleWith: nil)
        case .backIcon:
            return UIImage(named: "back", in: Bundle.primerResources, compatibleWith: nil)
        case .backIconRTL:
            return UIImage(named: "back-rtl", in: Bundle.primerResources, compatibleWith: nil)
        case .bankcontactCardIcon:
            return UIImage(named: "bancontact-icon", in: Bundle.primerResources, compatibleWith: nil)
        case .bankIcon:
            return UIImage(named: "bank", in: Bundle.primerResources, compatibleWith: nil)
        case .cameraIcon:
            return UIImage(named: "camera", in: Bundle.primerResources, compatibleWith: nil)
        case .checkmarkIcon:
            return UIImage(named: "check2", in: Bundle.primerResources, compatibleWith: nil)
        case .creditCardIcon:
            return UIImage(named: "creditCard", in: Bundle.primerResources, compatibleWith: nil)
        case .deleteIcon:
            return UIImage(named: "delete", in: Bundle.primerResources, compatibleWith: nil)
        case .discoverCardIcon:
            return UIImage(named: "discover", in: Bundle.primerResources, compatibleWith: nil)
        case .errorIcon:
            return UIImage(named: "error", in: Bundle.primerResources, compatibleWith: nil)
        case .forwardArrowIcon:
            return UIImage(named: "forwardDark", in: Bundle.primerResources, compatibleWith: nil)
        case .genericCardIcon:
            return UIImage(named: "genericCard", in: Bundle.primerResources, compatibleWith: nil)
        case .jcbCardIcon:
            return UIImage(named: "jcb-icon", in: Bundle.primerResources, compatibleWith: nil)
        case .klarnaLogo:
            return UIImage(named: "klarna", in: Bundle.primerResources, compatibleWith: nil)
        case .lockIcon:
            return UIImage(named: "lock", in: Bundle.primerResources, compatibleWith: nil)
        case .masterCardIcon:
            return UIImage(named: "masterCard", in: Bundle.primerResources, compatibleWith: nil)
        case .mobileIcon:
            return UIImage(named: "mobile", in: Bundle.primerResources, compatibleWith: nil)
        case .payPalLogoCopy:
            return UIImage(named: "paypal", in: Bundle.primerResources, compatibleWith: nil)
        case .payPalLogo:
            return UIImage(named: "paypal2", in: Bundle.primerResources, compatibleWith: nil)
        case .rightArrowIcon:
            return UIImage(named: "rightArrow", in: Bundle.primerResources, compatibleWith: nil)
        case .successIcon:
            return UIImage(named: "success", in: Bundle.primerResources, compatibleWith: nil)
        case .visaIcon:
            return UIImage(named: "visa", in: Bundle.primerResources, compatibleWith: nil)
        }
    }
}
