//
//  MerchantHUCRawPhoneNumberDataViewController.swift
//  Debug App
//
//  Created by Evangelos on 17/1/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import PrimerSDK
import UIKit

class MerchantHeadlessCheckoutRawPhoneNumberDataViewController: UIViewController, PrimerHeadlessUniversalCheckoutDelegate {
    
    static func instantiate(paymentMethodType: String) -> MerchantHeadlessCheckoutRawPhoneNumberDataViewController {
        let mpmvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MerchantHUCRawPhoneNumberDataViewController") as! MerchantHeadlessCheckoutRawPhoneNumberDataViewController
        mpmvc.paymentMethodType = paymentMethodType
        return mpmvc
    }
    
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var submitButton: UIButton!

    var paymentMethodType: String!
    var paymentId: String?
    var activityIndicator: UIActivityIndicatorView?
    var rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager!
    var rawData: PrimerRawData?
    
    var checkoutData: PrimerCheckoutData?
    var primerError: Error?
    var logs: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        phoneNumberTextField.text = "+628774494404"
        
        PrimerHeadlessUniversalCheckout.current.delegate = self
        
        do {
            self.rawDataManager = try PrimerHeadlessUniversalCheckout.RawDataManager(paymentMethodType: self.paymentMethodType)
            self.rawDataManager.delegate = self
        } catch {
            print(error)
        }
    }
    
    @IBAction func submitButtonTapped(_ sender: UIButton) {
        self.rawDataManager.rawData = PrimerPhoneNumberData(phoneNumber: self.phoneNumberTextField.text!)
        self.rawDataManager.submit()
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

// MARK: - PRIMER HEADLESS UNIVERSAL CHECKOUT DELEGATE

// MARK: Auto Payment Handling

extension MerchantHeadlessCheckoutRawPhoneNumberDataViewController {
    
    func primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) {
        print("\n\nMERCHANT APP\n\(#function)\ndata: \(data)")
        self.logs.append(#function)
        
        self.hideLoadingOverlay()
        
        let rvc = MerchantResultViewController.instantiate(checkoutData: self.checkoutData, error: self.primerError, logs: self.logs)
        self.navigationController?.pushViewController(rvc, animated: true)
    }
}

// MARK: Manual Payment Handling

extension MerchantHeadlessCheckoutRawPhoneNumberDataViewController {
    
    func primerHeadlessUniversalCheckoutDidTokenizePaymentMethod(_ paymentMethodTokenData: PrimerPaymentMethodTokenData, decisionHandler: @escaping (PrimerResumeDecision) -> Void) {
        print("\n\nMERCHANT APP\n\(#function)\npaymentMethodTokenData: \(paymentMethodTokenData)")
        self.logs.append(#function)
        
        Networking.createPayment(with: paymentMethodTokenData) { (res, err) in
            if let err = err {
                self.showErrorMessage(err.localizedDescription)
                self.hideLoadingOverlay()

            } else if let res = res {
                self.paymentId = res.id
                
                if res.requiredAction?.clientToken != nil {
                    decisionHandler(.continueWithNewClientToken(res.requiredAction!.clientToken))
                    
                } else {
                    self.hideLoadingOverlay()
                    let rvc = MerchantResultViewController.instantiate(checkoutData: self.checkoutData, error: self.primerError, logs: self.logs)
                    self.navigationController?.pushViewController(rvc, animated: true)
                }

            } else {
                assert(true)
            }
        }
    }
    
    func primerHeadlessUniversalCheckoutDidResumeWith(_ resumeToken: String, decisionHandler: @escaping (PrimerResumeDecision) -> Void) {
        print("\n\nMERCHANT APP\n\(#function)\nresumeToken: \(resumeToken)")
        self.logs.append(#function)
        
        Networking.resumePayment(self.paymentId!, withToken: resumeToken) { (res, err) in
            DispatchQueue.main.async {
                self.hideLoadingOverlay()
            }
            
            if let err = err {
                self.showErrorMessage(err.localizedDescription)
                decisionHandler(.fail(withErrorMessage: "Merchant App\nFailed to resume payment."))
            } else {
                decisionHandler(.succeed())
            }
            
            let rvc = MerchantResultViewController.instantiate(checkoutData: self.checkoutData, error: self.primerError, logs: self.logs)
            self.navigationController?.pushViewController(rvc, animated: true)
        }
    }
}

// MARK: Common

extension MerchantHeadlessCheckoutRawPhoneNumberDataViewController {

    func primerHeadlessUniversalCheckoutDidLoadAvailablePaymentMethods(_ paymentMethodTypes: [String]) {
        print("\n\nMERCHANT APP\n\(#function)")
        self.logs.append(#function)
    }
    
    func primerHeadlessUniversalCheckoutPreparationDidStart(for paymentMethodType: String) {
        print("\n\nMERCHANT APP\n\(#function)")
        self.logs.append(#function)
        self.showLoadingOverlay()
    }
    
    func primerHeadlessUniversalCheckoutTokenizationDidStart(for paymentMethodType: String) {
        print("\n\nMERCHANT APP\n\(#function)\npaymentMethodType: \(paymentMethodType)")
        self.logs.append(#function)
    }
    
    func primerHeadlessUniversalCheckoutPaymentMethodDidShow(for paymentMethodType: String) {
        print("\n\nMERCHANT APP\n\(#function)\npaymentMethodType: \(paymentMethodType)")
        self.logs.append(#function)
    }
    
    func primerHeadlessUniversalCheckoutDidReceiveAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo?) {
        print("\n\nMERCHANT APP\n\(#function)\nadditionalInfo: \(additionalInfo)")
        self.logs.append(#function)
        DispatchQueue.main.async {
            self.hideLoadingOverlay()
        }
    }
    
    func primerHeadlessUniversalCheckoutDidEnterResumePendingWithPaymentAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo?) {
        print("\n\nMERCHANT APP\n\(#function)\nadditionalInfo: \(additionalInfo)")
        self.logs.append(#function)
        self.hideLoadingOverlay()
    }
    
    func primerHeadlessUniversalCheckoutDidFail(withError err: Error) {
        print("\n\nMERCHANT APP\n\(#function)\nerror: \(err)")
        self.logs.append(#function)
        
        self.primerError = err
        self.hideLoadingOverlay()
    }
    
    func primerHeadlessUniversalCheckoutClientSessionWillUpdate() {
        print("\n\nMERCHANT APP\n\(#function)")
        self.logs.append(#function)
    }
    
    func primerHeadlessUniversalCheckoutClientSessionDidUpdate(_ clientSession: PrimerClientSession) {
        print("\n\nMERCHANT APP\n\(#function)\nclientSession: \(clientSession)")
        self.logs.append(#function)
    }
    
    func primerHeadlessUniversalCheckoutWillCreatePaymentWithData(_ data: PrimerCheckoutPaymentMethodData, decisionHandler: @escaping (PrimerPaymentCreationDecision) -> Void) {
        print("\n\nMERCHANT APP\n\(#function)\ndata: \(data)")
        self.logs.append(#function)
        decisionHandler(.continuePaymentCreation())
    }
}

extension MerchantHeadlessCheckoutRawPhoneNumberDataViewController: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate {
    
    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager, dataIsValid isValid: Bool, errors: [Error]?) {
        print("\n\nMERCHANT APP\n\(#function)\ndataIsValid: \(isValid)")
        self.logs.append(#function)
    }
    
    
    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager, metadataDidChange metadata: [String : Any]?) {
        print("\n\nMERCHANT APP\n\(#function)\nmetadataDidChange: \(metadata)")
        self.logs.append(#function)
    }
}

