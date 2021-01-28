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
    case success(type: SuccessScreenType)
    case error
    case singleFieldForm(type: TextFieldType)
    case confirmMandate
    case form(type: FormType)
    
    func viewControllerFactory(_ context: CheckoutContext, router: RouterDelegate) -> UIViewController {
        switch self {
        case .cardForm: return CardFormViewController(context.viewModelLocator.cardFormViewModel, router: router)
        case .cardScanner: return CardScannerViewController(viewModel: context.viewModelLocator.cardScannerViewModel, router: router)
        case .vaultCheckout: return VaultCheckoutViewController(context.viewModelLocator.vaultCheckoutViewModel, router: router)
        case .vaultPaymentMethods(let delegate):
            let vc = VaultPaymentMethodViewController(context.viewModelLocator.vaultPaymentMethodViewModel, router: router)
            vc.delegate = delegate
            return vc
        case .directCheckout:
            return DirectCheckoutViewController(with: context.viewModelLocator.directCheckoutViewModel, and: router)
        case .oAuth: return OAuthViewController(with: context.viewModelLocator.oAuthViewModel, router: router)
        case .applePay: return ApplePayViewController(with: context.viewModelLocator.applePayViewModel)
        case .success(let type):
            let vm = SuccessScreenViewModel(context: context, type: type)
            let vc = SuccessViewController(viewModel: vm)
            return vc
        case .error: return ErrorViewController()
        case .singleFieldForm(let type):
            let vm = SingleFieldFormViewModel(context: context, textFieldType: type)
            return SingleFieldFormViewController(viewModel: vm, router: router)
        case .confirmMandate:
            context.state.directDebitFormCompleted = true
            return ConfirmMandateViewController(viewModel: ConfirmMandateViewModel(context: context), router: router)
        case .form(let type):
            let vm = FormViewModel(context: context, formType: type)
            return FormViewController(viewModel: vm, router: router)
        }
    }
    
    var height: CGFloat {
        switch self {
        case .cardForm:  return 340
        case .cardScanner:  return 420
        case .vaultCheckout:  return 400
        case .vaultPaymentMethods:  return 320
        case .directCheckout:  return 320
        case .oAuth:  return 400
        case .applePay:  return 400
        case .success:  return 360
        case .error:  return 220
        case .singleFieldForm: return 288
        case .confirmMandate: return 640
        case .form(let type):
            switch type {
            case .address: return 460
            default: return 320
            }
        }
    }
}
