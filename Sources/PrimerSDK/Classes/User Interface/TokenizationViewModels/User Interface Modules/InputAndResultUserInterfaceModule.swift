//
//  InputAndResultUserInterfaceModule.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 01/11/22.
//

#if canImport(UIKit)

class InputAndResultUserInterfaceModule: NewUserInterfaceModule {
    
    override var navigationBarLogo: UIImage? {
        
        guard let internaPaymentMethodType = PrimerPaymentMethodType(rawValue: paymentMethodConfiguration.type) else {
            return super.navigationBarLogo
        }
        
        switch internaPaymentMethodType {
        case .adyenBlik:
            return UIScreen.isDarkModeEnabled ? logo : UIImage(named: "blik-logo-light", in: Bundle.primerResources, compatibleWith: nil)
        case .adyenMultibanco:
            return UIScreen.isDarkModeEnabled ? logo : UIImage(named: "multibanco-logo-light", in: Bundle.primerResources, compatibleWith: nil)
        default:
            return super.navigationBarLogo
        }
    }
    
    override func presentPreTokenizationViewControllerIfNeeded() -> Promise<Void> {
        return Promise { seal in
            switch self.paymentMethodConfiguration.type {
            case PrimerPaymentMethodType.adyenBlik.rawValue,
                PrimerPaymentMethodType.adyenMBWay.rawValue,
                PrimerPaymentMethodType.adyenMultibanco.rawValue:
                
                let pcfvc = PrimerInputViewController(
                    paymentMethodType: self.paymentMethodConfiguration.type,
                    userInterfaceModule: self)
                PrimerUIManager.primerRootViewController?.show(viewController: pcfvc)
                seal.fulfill()
                
            default:
                seal.fulfill()
            }
        }
    }
    
    override func presentPostPaymentViewControllerIfNeeded() -> Promise<Void> {
        return Promise { seal in
            switch self.paymentMethodConfiguration.type {
            case PrimerPaymentMethodType.adyenMBWay.rawValue:
                let vc = PrimerPaymentPendingInfoViewController(userInterfaceModule: self)
                PrimerUIManager.primerRootViewController?.show(viewController: vc)
                seal.fulfill()
            default:
                seal.fulfill()
            }
        }
    }
    
    override func presentResultViewControllerIfNeeded() -> Promise<Void> {
        return Promise { seal in
            switch self.paymentMethodConfiguration.type {
            case PrimerPaymentMethodType.adyenMultibanco.rawValue:
                
                let pcfvc = PrimerVoucherInfoPaymentViewController(
                    userInterfaceModule: self,
                    shouldShareVoucherInfoWithText: VoucherValue.sharableVoucherValuesText)
                
                PrimerUIManager.primerRootViewController?.show(viewController: pcfvc)
                seal.fulfill()
            default:
                seal.fulfill()
            }
        }
    }
}

#endif
