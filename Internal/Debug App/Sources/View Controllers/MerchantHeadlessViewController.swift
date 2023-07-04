//
//  MerchantHeadlessViewController.swift
//  Debug App
//
//  Created by Boris on 20.6.23..
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import UIKit
import PrimerSDK

class MerchantHeadlessViewController: UIViewController {
    
    var settings: PrimerSettings!
    var clientSession: ClientSessionRequestBody?
    var clientToken: String?

    class func instantiate(settings: PrimerSettings, clientSession: ClientSessionRequestBody?, clientToken: String?) -> MerchantHeadlessViewController {
        let mcvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MerchantHeadlessViewController") as! MerchantHeadlessViewController
        mcvc.settings = settings
        mcvc.clientSession = clientSession
        mcvc.clientToken = clientToken
        return mcvc
    }
    
    @IBAction func onCheckoutButtonTap(_ sender: Any) {
        let vc = MerchantHeadlessCheckoutAvailablePaymentMethodsViewController.instantiate(settings: settings,
                                                                                           clientSession: clientSession,
                                                                                           clientToken: clientToken)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func onVaultButtonTap(_ sender: Any) {
        let vc = MerchantHeadlesVaultManagerViewController.instantiate(settings: settings,
                                                                  clientSession: clientSession,
                                                                  clientToken: clientToken)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
