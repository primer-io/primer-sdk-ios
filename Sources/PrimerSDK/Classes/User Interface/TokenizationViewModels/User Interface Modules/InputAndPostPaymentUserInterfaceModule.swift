//
//  InputAndPostPaymentUserInterfaceModule.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 16/11/22.
//

#if canImport(UIKit)

// Bank selector
// Adyen dotPay

class InputAndPostPaymentUserInterfaceModule: NewUserInterfaceModule {
    
    // MARK: Overrides

    override var inputView: PrimerView? {
        get { _inputView }
        set { _inputView = newValue }
    }

    private lazy var _inputView: PrimerView? = {
        
        /*
             On the Bank selector actions, the `inputView`
             is shown as part of the
             `presentPreTokenizationViewControllerIfNeeded()` action
             No need to implement anything in the `inputView`
             for the payment methods requiring a Bank selector
         */

        return nil
    }()
    
    var banks: [AdyenBank] = []
    var didSelectBank: ((_ bank: AdyenBank) -> Void)?
        
    // MARK: Overrides
    
    override func presentPreTokenizationViewControllerIfNeeded() -> Promise<Void> {
        return Promise<Void> { seal in
            
            switch self.paymentMethodConfiguration.type {
            case PrimerPaymentMethodType.adyenDotPay.rawValue,
                PrimerPaymentMethodType.adyenIDeal.rawValue:
                PrimerUIManager.primerRootViewController?.show(viewController: self.makeBanksSelectorViewController(with: banks))
                seal.fulfill()
            default:
                seal.fulfill()
            }
        }
    }
}

extension InputAndPostPaymentUserInterfaceModule {
    
    internal func makeBanksSelectorViewController(with banks: [AdyenBank]) -> BankSelectorViewController {
        let bsvc = BankSelectorViewController(
            paymentMethodType: self.paymentMethodConfiguration.type,
            navigationBarImage: self.navigationBarLogo,
            banks: banks)
        bsvc.didSelectBank = { [weak self] bank in
            self?.didSelectBank?(bank)
        }
        return bsvc
    }

}

#endif
