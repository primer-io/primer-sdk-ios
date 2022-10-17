//
//  MerchantHUCRawCardDataViewController.swift
//  PrimerSDK_Example
//
//  Created by Evangelos on 12/7/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import PrimerSDK
import UIKit

class MerchantHUCRawDataViewController: UIViewController, PrimerHeadlessUniversalCheckoutDelegate {
    
    static func instantiate(paymentMethodType: String) -> MerchantHUCRawDataViewController {
        let mpmvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MerchantHUCRawDataViewController") as! MerchantHUCRawDataViewController
        mpmvc.paymentMethodType = paymentMethodType
        return mpmvc
    }
    
    var stackView: UIStackView!
    var paymentMethodType: String!
    var paymentId: String?
    var activityIndicator: UIActivityIndicatorView?
    var rawData: PrimerRawData?
    
    var cardnumberTextField: UITextField!
    var expiryDateTextField: UITextField!
    var cvvTextField: UITextField!
    var cardholderNameTextField: UITextField!
    var payButton: UIButton!
    
    var checkoutData: [String] = []
    var primerError: Error?
    var logs: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.stackView = UIStackView()
        self.stackView.axis = .vertical
        self.stackView.spacing = 6
        self.view.addSubview(self.stackView)
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        self.stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        self.stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        
        self.cardnumberTextField = UITextField(frame: .zero)
        self.cardnumberTextField.accessibilityIdentifier = "card_txt_fld"
        self.cardnumberTextField.borderStyle = .line
        self.cardnumberTextField.layer.borderColor = UIColor.black.cgColor
        self.stackView.addArrangedSubview(self.cardnumberTextField)
        self.cardnumberTextField.translatesAutoresizingMaskIntoConstraints = false
        self.cardnumberTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        self.cardnumberTextField.placeholder = "4242 4242 4242 4242"
        
        self.expiryDateTextField = UITextField(frame: .zero)
        self.expiryDateTextField.accessibilityIdentifier = "expiry_txt_fld"
        self.expiryDateTextField.borderStyle = .line
        self.expiryDateTextField.layer.borderColor = UIColor.black.cgColor
        self.stackView.addArrangedSubview(self.expiryDateTextField)
        self.expiryDateTextField.translatesAutoresizingMaskIntoConstraints = false
        self.expiryDateTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        self.expiryDateTextField.placeholder = "03/30"
        
        if paymentMethodType == "PAYMENT_CARD" {
            self.cvvTextField = UITextField(frame: .zero)
            self.cvvTextField.accessibilityIdentifier = "cvc_txt_fld"
            self.cvvTextField.borderStyle = .line
            self.cvvTextField.layer.borderColor = UIColor.black.cgColor
            self.stackView.addArrangedSubview(self.cvvTextField)
            self.cvvTextField.translatesAutoresizingMaskIntoConstraints = false
            self.cvvTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true
            self.cvvTextField.placeholder = "123"
        }
        
        self.cardholderNameTextField = UITextField(frame: .zero)
        self.cardholderNameTextField.accessibilityIdentifier = "card_holder_txt_fld"
        self.cardholderNameTextField.borderStyle = .line
        self.cardholderNameTextField.layer.borderColor = UIColor.black.cgColor
        self.stackView.addArrangedSubview(self.cardholderNameTextField)
        self.cardholderNameTextField.translatesAutoresizingMaskIntoConstraints = false
        self.cardholderNameTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        self.cardholderNameTextField.placeholder = "John Smith"
        
        self.payButton = UIButton(frame: .zero)
        self.stackView.addArrangedSubview(self.payButton)
        self.payButton.accessibilityIdentifier = "submit_btn"
        self.payButton.translatesAutoresizingMaskIntoConstraints = false
        self.payButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        self.payButton.setTitle("Pay", for: .normal)
        self.payButton.titleLabel?.adjustsFontSizeToFitWidth = true
        self.payButton.titleLabel?.minimumScaleFactor = 0.7
        self.payButton.backgroundColor = .black
        self.payButton.setTitleColor(.white, for: .normal)
        self.payButton.addTarget(self, action: #selector(payButtonTapped), for: .touchUpInside)
        
        
        PrimerHeadlessUniversalCheckout.current.delegate = self
        
        self.showLoadingOverlay()
        
        Networking.requestClientSession(requestBody: clientSessionRequestBody) { (clientToken, err) in
            if let err = err {
                self.showErrorMessage(err.localizedDescription)
 
            } else if let clientToken = clientToken {
                let settings = PrimerSettings(
                    paymentHandling: paymentHandling == .auto ? .auto : .manual,
                    paymentMethodOptions: PrimerPaymentMethodOptions(
                        urlScheme: "merchant://redirect",
                        applePayOptions: PrimerApplePayOptions(merchantIdentifier: "merchant.dx.team", merchantName: "Primer Merchant", isCaptureBillingAddressEnabled: false)
                    )
                )
                
                PrimerHeadlessUniversalCheckout.current.start(withClientToken: clientToken, settings: settings, completion: { (pms, err) in
                    self.hideLoadingOverlay()
                })
            }
        }
    }
    
    @IBAction func payButtonTapped(_ sender: UIButton) {
        do {
            guard expiryDateTextField.text?.count == 5,
                  let expiryComponents = expiryDateTextField.text?.split(separator: "/") else {
                self.showErrorMessage("Please write expiry date in format MM/YY")
                return
            }
            
            if expiryComponents.count != 2 {
                self.showErrorMessage("Please write expiry date in format MM/YY")
                return
            }
            
            let primerRawDataManager = try PrimerHeadlessUniversalCheckout.RawDataManager(paymentMethodType: self.paymentMethodType)
            primerRawDataManager.delegate = self
            
            if paymentMethodType == "PAYMENT_CARD" {
                self.rawData = PrimerCardData(
                    cardNumber: self.cardnumberTextField.text ?? "",
                    expiryMonth: String(expiryComponents[0]),
                    expiryYear: "20\(String(expiryComponents[1]))",
                    cvv: self.cvvTextField.text ?? "",
                    cardholderName: self.cardholderNameTextField.text)
                
                primerRawDataManager.rawData = self.rawData!
                primerRawDataManager.submit()
                self.showLoadingOverlay()
                
            } else if paymentMethodType == "ADYEN_BANCONTACT_CARD" {
                self.rawData = PrimerBancontactCardRedirectData(
                    cardNumber: self.cardnumberTextField.text ?? "",
                    expiryMonth: String(expiryComponents[0]),
                    expiryYear: "20\(String(expiryComponents[1]))",
                    cardholderName: self.cardholderNameTextField.text ?? "")
                
                primerRawDataManager.rawData = self.rawData!
                primerRawDataManager.submit()
                self.showLoadingOverlay()
            }
            
        } catch {
            self.showErrorMessage(error.localizedDescription)
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

// MARK: - PRIMER HEADLESS UNIVERSAL CHECKOUT DELEGATE

// MARK: Auto Payment Handling

extension MerchantHUCRawDataViewController {
    
    func primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) {
        print("\n\nMERCHANT APP\n\(#function)\ndata: \(data)")
        self.logs.append(#function)
        
        if let checkoutDataDictionary = try? data.asDictionary(),
           let jsonData = try? JSONSerialization.data(withJSONObject: checkoutDataDictionary, options: .prettyPrinted),
           let jsonString = jsonData.prettyPrintedJSONString {
            self.checkoutData.append(jsonString as String)
        }
        
        self.hideLoadingOverlay()
        
        let rvc = MerchantResultViewController.instantiate(checkoutData: self.checkoutData, error: self.primerError, logs: self.logs)
        self.navigationController?.pushViewController(rvc, animated: true)
    }
}

// MARK: Manual Payment Handling

extension MerchantHUCRawDataViewController {
    
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

extension MerchantHUCRawDataViewController {

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

extension MerchantHUCRawDataViewController: PrimerRawDataManagerDelegate {
    
    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager, dataIsValid isValid: Bool, errors: [Error]?) {
        print("\n\nMERCHANT APP\n\(#function)\ndataIsValid: \(isValid)")
        self.logs.append(#function)
    }
    
    
    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager, metadataDidChange metadata: [String : Any]?) {
        print("\n\nMERCHANT APP\n\(#function)\nmetadataDidChange: \(metadata)")
        self.logs.append(#function)
    }
}
