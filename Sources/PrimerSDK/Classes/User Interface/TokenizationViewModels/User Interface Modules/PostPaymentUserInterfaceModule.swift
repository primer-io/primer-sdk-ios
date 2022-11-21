//
//  PostPaymentUserInterfaceModule.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 16/11/22.
//

#if canImport(UIKit)

import SafariServices

// Web redirects
class PostPaymentUserInterfaceModule: NewUserInterfaceModule {
    
    // MARK: Overrides
    
    override func presentPostPaymentViewControllerIfNeeded() -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async { [unowned self] in
                let safariVC = SFSafariViewController(url: (self.paymentModule as! WebRedirectPaymentModule).redirectUrl)
                safariVC.delegate = self.paymentModule as! WebRedirectPaymentModule
                
                PrimerUIManager.primerRootViewController?.present(safariVC, animated: true, completion: {
                    DispatchQueue.main.async {
                        PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutPaymentMethodDidShow?(for: self.paymentMethodConfiguration.type)
                        seal.fulfill(())
                    }
                })
            }
        }
    }
}

#endif
