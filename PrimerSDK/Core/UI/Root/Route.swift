//
//  Route.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 17/01/2021.
//
import UIKit

enum OAuthHost {
    case paypal
    case klarna
}

enum Route {
    case cardScanner(delegate: CardScannerViewControllerDelegate)
    case vaultCheckout
    case vaultPaymentMethods(delegate: ReloadDelegate)
    case oAuth(host: OAuthHost)
    case applePay
    case success(type: SuccessScreenType)
    case error(message: String = "")
    case confirmMandate
    case form(type: FormType, closeOnSubmit: Bool = false)
    
    var viewController: UIViewController? {
        switch self {
        case .cardScanner(let delegate):
            if #available(iOS 12, *) {
                let vc = CardScannerViewController()
                vc.delegate = delegate
                return vc
            } else {
                return nil
            }
        case .vaultCheckout:
            return VaultCheckoutViewController()
        case .vaultPaymentMethods(let delegate):
            let vc = VaultPaymentMethodViewController()
            vc.delegate = delegate
            return vc
        case .oAuth(let host):
            if #available(iOS 11.0, *) {
                return OAuthViewController(host: host)
            } else {
                return nil
            }
        case .applePay:
            return ApplePayViewController()
        case .success:
            return SuccessViewController()
        case .error(let message):
            return ErrorViewController(message: message)
        case .confirmMandate:
            return ConfirmMandateViewController()
        case .form(let type, _):
            let state: AppStateProtocol = DependencyContainer.resolve()
            state.routerState.formType = type
            return FormViewController()
        }
    }
    
    var height: CGFloat {
        switch self {
        case .cardScanner:  return 420
        case .vaultCheckout:  return 400
        case .vaultPaymentMethods:  return 320
        case .oAuth:  return 400
        case .applePay:  return 400
        case .success:  return 360
        case .error:  return 220
        case .confirmMandate: return 580
        case .form(let type, _):
            switch type {
            case .address: return 460
            case .name, .iban, .email: return 300
            case .cardForm(let theme):
                switch theme.textFieldTheme {
                case .doublelined: return 360
                default: return 320
                }
            default: return 320
            }
        }
    }
}
