////
////  Route.swift
////  PrimerSDK
////
////  Created by Carl Eriksson on 17/01/2021.
////
//
//#if canImport(UIKit)
//
//import UIKit
//
//enum Route {
//    #if canImport(CardScan)
//    case cardScanner(delegate: CardScannerViewControllerDelegate)
//    #endif
//    case vaultCheckout
//    case vaultPaymentMethods(delegate: ReloadDelegate)
//    case oAuth(host: OAuthHost)
//    case applePay
//    case success(type: SuccessScreenType)
//    case error(error: Error)
//    case confirmMandate
//    case form(type: FormType, closeOnSubmit: Bool = false)
//
//    var viewController: PrimerViewController? {
//        switch self {
//        #if canImport(CardScan)
//        case .cardScanner(let delegate):
//            if #available(iOS 12, *) {
//                let vc = CardScannerViewController()
//                vc.delegate = delegate
//                return vc
//            } else {
//                return nil
//            }
//        #endif
//        case .vaultCheckout:
//            return VaultCheckoutViewController()
//        case .vaultPaymentMethods(let delegate):
//            let vc = VaultPaymentMethodViewController()
//            vc.delegate = delegate
//            return vc
//        case .oAuth(let host):
//            switch host {
//            case .apaya:
//                let viewModel: ApayaLoadWebViewModel = DependencyContainer.resolve()
//                return PrimerLoadWebViewController(with: viewModel)
//            default:
//                if #available(iOS 11.0, *) {
//                    return OAuthViewController(host: host)
//                } else {
//                    return nil
//                }
//            }
//        case .applePay:
//            return nil
//        case .success(let screenType):
//            let vc = SuccessViewController()
//            vc.screenType = screenType
//            return vc
//        case .error(let error):
//            Primer.shared.delegate?.checkoutFailed?(with: error)
//            return ErrorViewController(message: error.localizedDescription)
//        case .confirmMandate:
//            return ConfirmMandateViewController()
//        case .form(let type, _):
//            let state: AppStateProtocol = DependencyContainer.resolve()
//            state.routerState.formType = type
//            return FormViewController()
//        }
//    }
//
//    var height: CGFloat {
//        switch self {
//        #if canImport(CardScan)
//        case .cardScanner:
//            return 420
//        #endif
//        case .vaultCheckout:
//            return Primer.shared.flow.internalSessionFlow.vaulted ? 400 : 600
//        case .vaultPaymentMethods:
//            return 320
//        case .oAuth:
//            return 400
//        case .applePay:
//            return 400
//        case .success:
//            return 360
//        case .error:
//            return 320
//        case .confirmMandate:
//            return 580
//        case .form(let type, _):
//            switch type {
//            case .address:
//                return 460
//            case .name,
//                 .iban,
//                 .email:
//                return 300
//            case .cardForm(let theme):
//                switch theme.textFieldTheme {
//                case .doublelined:
//                    return 400
//                default:
//                    return 360
//                }
//            default:
//                return 320
//            }
//        }
//    }
//}
//
//#endif
