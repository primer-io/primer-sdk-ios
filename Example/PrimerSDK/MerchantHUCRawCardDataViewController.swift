//
//  MerchantHUCRawCardDataViewController.swift
//  PrimerSDK_Example
//
//  Created by Evangelos on 12/7/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import PrimerSDK
import UIKit

class MerchantHUCRawCardDataViewController: UIViewController {
    
    static func instantiate(
        amount: Int,
        currency: Currency,
        countryCode: CountryCode,
        customerId: String?,
        phoneNumber: String?
    ) -> MerchantHUCRawCardDataViewController {
        let mpmvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MerchantHUCRawCardDataViewController") as! MerchantHUCRawCardDataViewController
        mpmvc.amount = amount
        mpmvc.currency = currency
        mpmvc.countryCode = countryCode
        mpmvc.customerId = customerId
        mpmvc.phoneNumber = phoneNumber
        return mpmvc
    }

    var amount: Int!
    var currency: Currency!
    var countryCode: CountryCode!
    var availablePaymentMethods: [String] = []
    var customerId: String?
    var phoneNumber: String?
    private var paymentId: String?
    var activityIndicator: UIActivityIndicatorView?
    
    var rawCardData: PrimerCardData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PrimerHeadlessUniversalCheckout.current.delegate = self
        
        self.showLoadingOverlay()
        
        let clientSessionRequestBody = Networking().clientSessionRequestBodyWithCurrency(customerId ?? String.randomString(length: 8),
                                                                                         phoneNumber: phoneNumber,
                                                                                         countryCode: countryCode,
                                                                                         currency: currency,
                                                                                         amount: amount)

        Networking.requestClientSession(requestBody: clientSessionRequestBody) { (clientToken, err) in
            if let err = err {
                print(err)
                let merchantErr = NSError(domain: "merchant-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch client token"])
                print(merchantErr)
                
            } else if let clientToken = clientToken {
                let settings = PrimerSettings(
                    paymentHandling: paymentHandling == .auto ? .auto : .manual,
                    paymentMethodOptions: PrimerPaymentMethodOptions(
                        urlScheme: "merchant://redirect",
                        applePayOptions: PrimerApplePayOptions(merchantIdentifier: "merchant.dx.team", merchantName: "Primer Merchant")
                    )
                )
                
                PrimerHeadlessUniversalCheckout.current.start(withClientToken: clientToken, settings: settings, completion: { (pms, err) in
                    self.hideLoadingOverlay()
                    
                    do {
                        let primerRawDataManager = try PrimerHeadlessUniversalCheckout.RawDataManager(paymentMethodType: "PAYMENT_CARD")
                        primerRawDataManager.delegate = self
                        
                        self.rawCardData = PrimerCardData(
                            number: "424242424242424",
                            expiryMonth: "12",
                            expiryYear: "2025",
                            cvv: "123",
                            cardholderName: "John Smith")
                        primerRawDataManager.rawData = self.rawCardData!
                        
                        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
                            self.rawCardData!.number = "4242424242424242"
                            primerRawDataManager.submit()
                        }
                        
                        
                    } catch {
                        
                    }
                    
                })
            }
        }
    }
    
    // MARK: - HELPERS
    
    private func showLoadingOverlay() {
        DispatchQueue.main.async {
            self.activityIndicator = UIActivityIndicatorView(frame: self.view.bounds)
            self.view.addSubview(self.activityIndicator!)
            self.activityIndicator?.backgroundColor = .black.withAlphaComponent(0.2)
            self.activityIndicator?.color = .black
            self.activityIndicator?.startAnimating()
        }
    }
    
    private func hideLoadingOverlay() {
        DispatchQueue.main.async {
            self.activityIndicator?.stopAnimating()
            self.activityIndicator?.removeFromSuperview()
            self.activityIndicator = nil
        }
    }
}

extension MerchantHUCRawCardDataViewController: PrimerHeadlessUniversalCheckoutDelegate {

    func primerHeadlessUniversalCheckoutDidLoadAvailablePaymentMethods(_ paymentMethodTypes: [String]) {
        print("\n\n🤯🤯🤯 \(#function)\npaymentMethodType: \(paymentMethodTypes)")
    }
    
    func primerHeadlessUniversalCheckoutPreparationDidStart(for paymentMethodType: String) {
        print("\n\n🤯🤯🤯 \(#function)\npaymentMethodType: \(paymentMethodType)")
        self.showLoadingOverlay()
    }
    
    func primerHeadlessUniversalCheckoutTokenizationDidStart(for paymentMethodType: String) {
        print("\n\n🤯🤯🤯 \(#function)\npaymentMethodType: \(paymentMethodType)")
    }
    
    func primerHeadlessUniversalCheckoutPaymentMethodDidShow(for paymentMethodType: String) {
        print("\n\n🤯🤯🤯 \(#function)\npaymentMethodType: \(paymentMethodType)")
    }
    
    func primerHeadlessUniversalCheckoutDidTokenizePaymentMethod(_ paymentMethodTokenData: PrimerPaymentMethodTokenData, decisionHandler: @escaping (PrimerResumeDecision) -> Void) {
        print("\n\n🤯🤯🤯 \(#function)\npaymentMethodTokenData: \(paymentMethodTokenData)")
        
        Networking.createPayment(with: paymentMethodTokenData) { (res, err) in
            if let err = err {
                DispatchQueue.main.async {
                    self.hideLoadingOverlay()
                }
            } else if let res = res {
                self.paymentId = res.id
                
                if res.requiredAction?.clientToken != nil {
                    decisionHandler(.continueWithNewClientToken(res.requiredAction!.clientToken))
                } else {
                    DispatchQueue.main.async {
                        self.hideLoadingOverlay()
                    }
                    
                    if let data = try? JSONEncoder().encode(res) {
                        DispatchQueue.main.async {
//                            let rvc = HUCResultViewController.instantiate(data: [data])
//                            self.navigationController?.pushViewController(rvc, animated: true)
                        }
                    }
                }

            } else {
                assert(true)
            }
        }
    }
    
    func primerHeadlessUniversalCheckoutDidResumeWith(_ resumeToken: String, decisionHandler: @escaping (PrimerResumeDecision) -> Void) {
        print("\n\n🤯🤯🤯 \(#function)\nresumeToken: \(resumeToken)")
        
        Networking.resumePayment(self.paymentId!, withToken: resumeToken) { (res, err) in
            DispatchQueue.main.async {
                self.hideLoadingOverlay()
            }
            
            if let err = err {
                decisionHandler(.fail(withErrorMessage: "Merchant App\nFailed to resume payment."))
            } else {
                decisionHandler(.succeed())
            }
        }
    }
    
    func primerHeadlessUniversalCheckoutDidFail(withError err: Error) {
        print("\n\n🤯🤯🤯 \(#function)\nerror: \(err)")
        
        DispatchQueue.main.async {
            self.hideLoadingOverlay()
        }
    }
    
    func primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) {
        print("\n\n🤯🤯🤯 \(#function)\ndata: \(data)")
        
        DispatchQueue.main.async {
            self.hideLoadingOverlay()
        }
    }
    
    func primerHeadlessUniversalCheckoutClientSessionWillUpdate() {
        print("\n\n🤯🤯🤯 \(#function)")
    }
    
    func primerHeadlessUniversalCheckoutClientSessionDidUpdate(_ clientSession: PrimerClientSession) {
        print("\n\n🤯🤯🤯 \(#function)\nclientSession: \(clientSession)")
    }
    
    func primerHeadlessUniversalCheckoutWillCreatePaymentWithData(_ data: PrimerCheckoutPaymentMethodData, decisionHandler: @escaping (PrimerPaymentCreationDecision) -> Void) {
        print("\n\n🤯🤯🤯 \(#function)\ndata: \(data)")
        decisionHandler(.continuePaymentCreation())
    }
}

extension MerchantHUCRawCardDataViewController: PrimerRawDataManagerDelegate {
    
    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager, dataIsValid isValid: Bool, errors: [Error]?) {
        
    }
    
    
    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager, dataDidChange rawData: PrimerRawData?) {
        
    }
}
