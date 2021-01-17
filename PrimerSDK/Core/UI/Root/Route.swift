//
//  Route.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 17/01/2021.
//
import UIKit

enum Route {
    case cardForm
    case cardScanner(delegate: CardScannerViewControllerDelegate)
    case vaultCheckout
    case vaultPaymentMethods(delegate: ReloadDelegate)
    case directCheckout
    case oAuth
    case applePay
    case success
    case error
    
    func viewControllerFactory(_ context: CheckoutContext, router: RouterDelegate) -> UIViewController {
        switch self {
        case .cardForm: return CardFormViewController(context.viewModelLocator.cardFormViewModel, router: router)
        case .cardScanner: return CardScannerViewController(viewModel: context.viewModelLocator.cardScannerViewModel, router: router)
        case .vaultCheckout: return VaultCheckoutViewController(context.viewModelLocator.vaultCheckoutViewModel, router: router)
        case .vaultPaymentMethods(let delegate):
            let vc = VaultPaymentMethodViewController(context.viewModelLocator.vaultPaymentMethodViewModel, router: router)
            vc.delegate = delegate
            return vc
        case .directCheckout: return DirectCheckoutViewController(with: context.viewModelLocator.directCheckoutViewModel, and: router)
        case .oAuth: return OAuthViewController(with: context.viewModelLocator.oAuthViewModel, router: router)
        case .applePay: return ApplePayViewController(with: context.viewModelLocator.applePayViewModel)
        case .success: return SuccessViewController()
        case .error: return ErrorViewController()
        }
    }
    
    var height: CGFloat {
        switch self {
        case .cardForm:  return 312
        case .cardScanner:  return 400
        case .vaultCheckout:  return 240
        case .vaultPaymentMethods:  return 320
        case .directCheckout:  return 320
        case .oAuth:  return 400
        case .applePay:  return 400
        case .success:  return 220
        case .error:  return 220
        }
    }
}
