//
//  MerchantPaymentMethodsViewController.swift
//  PrimerSDK_Example
//
//  Created by Evangelos on 2/2/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import PrimerSDK
import UIKit

class MerchantHeadlessCheckoutAvailablePaymentMethodsViewController: UIViewController, PrimerHeadlessUniversalCheckoutDelegate {
    
    class func instantiate(settings: PrimerSettings, clientSession: ClientSessionRequestBody?, clientToken: String?) -> MerchantHeadlessCheckoutAvailablePaymentMethodsViewController {
        let mpmvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MerchantHUCPaymentMethodsViewController") as! MerchantHeadlessCheckoutAvailablePaymentMethodsViewController
        mpmvc.settings = settings
        mpmvc.clientSession = clientSession
        mpmvc.clientToken = clientToken
        return mpmvc
    }
    
    var settings: PrimerSettings!
    var clientSession: ClientSessionRequestBody?
    var clientToken: String?

    var amount: Int!
    var currency: Currency!
    var countryCode: CountryCode!
    var availablePaymentMethods: [PrimerHeadlessUniversalCheckout.PaymentMethod] = []
    var customerId: String?
    var phoneNumber: String?
    private var paymentId: String?
    var checkoutData: PrimerCheckoutData?
    var primerError: Error?
    
    var redirectManager: PrimerHeadlessUniversalCheckout.NativeUIManager?
    var logs: [String] = []

    @IBOutlet weak var tableView: UITableView!
    var activityIndicator: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PrimerHeadlessUniversalCheckout.current.delegate = self
        PrimerHeadlessUniversalCheckout.current.uiDelegate = self
        
        self.showLoadingOverlay()
        
        if let clientToken = clientToken {
            PrimerHeadlessUniversalCheckout.current.start(withClientToken: clientToken, settings: self.settings, completion: { (pms, err) in
                self.hideLoadingOverlay()
                
                DispatchQueue.main.async {
                    self.availablePaymentMethods = pms ?? []
                    self.tableView.reloadData()
                }
            })
            
        } else if let clientSession = clientSession {
            Networking.requestClientSession(requestBody: clientSession) { (clientToken, err) in
                self.hideLoadingOverlay()
                
                if let err = err {
                    print(err)
                    let merchantErr = NSError(domain: "merchant-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch client token"])
                    print(merchantErr)
                    
                } else if let clientToken = clientToken {
                    self.clientToken = clientToken
                    
                    PrimerHeadlessUniversalCheckout.current.start(withClientToken: clientToken, settings: self.settings, completion: { (pms, err) in
                        DispatchQueue.main.async {
                            self.availablePaymentMethods = pms ?? []
                            self.tableView.reloadData()
                        }
                    })
                }
            }
        } else {
            fatalError()
        }
    }
    
    // MARK: - HELPERS
    
    private func showLoadingOverlay() {
        DispatchQueue.main.async {
            if self.activityIndicator != nil { return }
            
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

extension MerchantHeadlessCheckoutAvailablePaymentMethodsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.availablePaymentMethods.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let paymentMethod = self.availablePaymentMethods[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "MerchantPaymentMethodCell", for: indexPath) as! MerchantPaymentMethodCell
        cell.configure(paymentMethod: paymentMethod)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let paymentMethodType = self.availablePaymentMethods[indexPath.row].paymentMethodType
        if paymentMethodType == "PAYMENT_CARD" ||
            paymentMethodType == "ADYEN_BANCONTACT_CARD"
        {
            let alert = UIAlertController(title: "", message: "Select Implementation", preferredStyle: .actionSheet)
            
            let rawDataAlertAction = UIAlertAction(title: "Raw Data", style: .default , handler:{ (UIAlertAction)in
                let vc = MerchantHeadlessCheckoutRawDataViewController.instantiate(paymentMethodType: paymentMethodType)
                self.navigationController?.pushViewController(vc, animated: true)
            })
            rawDataAlertAction.accessibilityIdentifier = "raw_data_huc_alert_action"
            
            let cardComponentsAlertAction = UIAlertAction(title: "Card Components", style: .default , handler:{ (UIAlertAction)in
                let vc = MerchantHeadlessCheckoutCardComponentsViewController.instantiate(paymentMethodType: paymentMethodType)
                self.navigationController?.pushViewController(vc, animated: true)
            })
            cardComponentsAlertAction.accessibilityIdentifier = "card_components_huc_data_alert_action"
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            cancelAction.accessibilityIdentifier = "cancel_huc_alert_action"
            
            alert.addAction(cardComponentsAlertAction)
            alert.addAction(rawDataAlertAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
            
        } else if paymentMethodType == "XENDIT_RETAIL_OUTLETS" {
            let vc = MerchantHeadlessCheckoutRawRetailDataViewController.instantiate(paymentMethodType: paymentMethodType)
            self.navigationController?.pushViewController(vc, animated: true)
        } else if paymentMethodType == "XENDIT_OVO" {
            let vc = MerchantHeadlessCheckoutRawPhoneNumberDataViewController.instantiate(paymentMethodType: paymentMethodType)
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            redirectManager = try? PrimerHeadlessUniversalCheckout.NativeUIManager(paymentMethodType: paymentMethodType)
            try? redirectManager?.showPaymentMethod(intent: .checkout)
        }
    }
}

// MARK: Manual Payment Handling

extension MerchantHeadlessCheckoutAvailablePaymentMethodsViewController {
    
    func primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) {
        print("\n\nMERCHANT APP\n\(#function)\ndata: \(data)")
        self.logs.append(#function)
        self.checkoutData = data
        self.hideLoadingOverlay()
        
        let rvc = MerchantResultViewController.instantiate(checkoutData: self.checkoutData, error: self.primerError, logs: self.logs)
        self.navigationController?.pushViewController(rvc, animated: true)
    }
    
    func primerHeadlessUniversalCheckoutDidStartTokenization(for paymentMethodType: String) {
        print("\n\nMERCHANT APP\n\(#function)\npaymentMethodType: \(paymentMethodType)")
        self.logs.append(#function)
    }
    
    func primerHeadlessUniversalCheckoutDidTokenizePaymentMethod(_ paymentMethodTokenData: PrimerPaymentMethodTokenData, decisionHandler: @escaping (PrimerHeadlessUniversalCheckoutResumeDecision) -> Void) {
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
                    DispatchQueue.main.async {
                        self.hideLoadingOverlay()
                    }
                    
                    if let data = try? JSONEncoder().encode(res) {
//                        DispatchQueue.main.async {
//                            let rvc = HUCResultViewController.instantiate(data: [data])
//                            self.navigationController?.pushViewController(rvc, animated: true)
//                        }
                    }
                    
                    decisionHandler(.complete())
                }
                
            } else {
                assert(true)
            }
        }
    }
    
    func primerHeadlessUniversalCheckoutDidResumeWith(_ resumeToken: String, decisionHandler: @escaping (PrimerHeadlessUniversalCheckoutResumeDecision) -> Void) {
        print("\n\nMERCHANT APP\n\(#function)\nresumeToken: \(resumeToken)")
        self.logs.append(#function)

        Networking.resumePayment(self.paymentId!, withToken: resumeToken) { (res, err) in
            DispatchQueue.main.async {
                self.hideLoadingOverlay()
            }

            if let clientToken = res?.requiredAction?.clientToken {
                decisionHandler(.continueWithNewClientToken(clientToken))
            } else {
                print("Payment has been resumed")
                decisionHandler(.complete())
            }

            let rvc = MerchantResultViewController.instantiate(checkoutData: nil, error: self.primerError, logs: self.logs)
            self.navigationController?.pushViewController(rvc, animated: true)
        }
    }
}

// MARK: Common

extension MerchantHeadlessCheckoutAvailablePaymentMethodsViewController {
    
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
    
    func primerHeadlessUniversalCheckoutDidFail(withError err: Error, checkoutData: PrimerCheckoutData?) {
        print("\n\nMERCHANT APP\n\(#function)\nerror: \(err)\ncheckoutData: \(checkoutData)")
        self.logs.append(#function)
        self.primerError = err
        self.hideLoadingOverlay()
        
        let rvc = MerchantResultViewController.instantiate(checkoutData: self.checkoutData, error: self.primerError, logs: self.logs)
        self.navigationController?.pushViewController(rvc, animated: true)
    }
    
    func primerHeadlessUniversalCheckoutWillUpdateClientSession() {
        print("\n\nMERCHANT APP\n\(#function)")
        self.logs.append(#function)
    }
    
    func primerHeadlessUniversalCheckoutDidUpdateClientSession(_ clientSession: PrimerClientSession) {
        print("\n\nERCHANT APP\n\(#function)\nclientSession: \(clientSession)")
        self.logs.append(#function)
    }
    
    func primerHeadlessUniversalCheckoutWillCreatePaymentWithData(_ data: PrimerCheckoutPaymentMethodData, decisionHandler: @escaping (PrimerPaymentCreationDecision) -> Void) {
        print("\n\nMERCHANT APP\n\(#function)\ndata: \(data)")
        self.logs.append(#function)
        decisionHandler(.continuePaymentCreation())
    }
}

extension MerchantHeadlessCheckoutAvailablePaymentMethodsViewController: PrimerHeadlessUniversalCheckoutUIDelegate {
    
    func primerHeadlessUniversalCheckoutUIDidStartPreparation(for paymentMethodType: String) {
        print("\n\nMERCHANT APP\n\(#function)")
        self.logs.append(#function)
        self.showLoadingOverlay()
    }
    
    func primerHeadlessUniversalCheckoutUIDidShowPaymentMethod(for paymentMethodType: String) {
        print("\n\nMERCHANT APP\n\(#function)\npaymentMethodType: \(paymentMethodType)")
        self.logs.append(#function)
    }
}

class MerchantPaymentMethodCell: UITableViewCell {
    
    @IBOutlet weak var paymentMethodLabel: UILabel!
    @IBOutlet weak var buttonContainerView: UIView!
    
    var paymentMethod: PrimerHeadlessUniversalCheckout.PaymentMethod!
    
    func configure(paymentMethod: PrimerHeadlessUniversalCheckout.PaymentMethod) {
        self.paymentMethod = paymentMethod
        paymentMethodLabel.text = paymentMethod.paymentMethodType
        
        let paymentMethodAsset = try? PrimerHeadlessUniversalCheckout.AssetsManager.getPaymentMethodAsset(for: paymentMethod.paymentMethodType)
        
        let paymentMethodButton = UIButton()
        buttonContainerView.addSubview(paymentMethodButton)
        
        paymentMethodButton.accessibilityIdentifier = paymentMethod.paymentMethodType
        paymentMethodButton.clipsToBounds = true
        paymentMethodButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        paymentMethodButton.imageEdgeInsets = UIEdgeInsets(top: 12,
                                                           left: 16,
                                                           bottom: 12,
                                                           right: 16)
        paymentMethodButton.contentMode = .scaleAspectFit
        paymentMethodButton.imageView?.contentMode = .scaleAspectFit
        paymentMethodButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        paymentMethodButton.layer.cornerRadius = 4
        
        paymentMethodButton.backgroundColor = paymentMethodAsset?.paymentMethodBackgroundColor.colored ?? paymentMethodAsset?.paymentMethodBackgroundColor.light
        paymentMethodButton.setImage(paymentMethodAsset?.paymentMethodLogo.colored ?? paymentMethodAsset?.paymentMethodLogo.light, for: .normal)
        paymentMethodButton.setTitleColor(.black, for: .normal)

        paymentMethodButton.translatesAutoresizingMaskIntoConstraints = false
        paymentMethodButton.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        paymentMethodButton.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        paymentMethodButton.topAnchor.constraint(equalTo: topAnchor).isActive = true
        paymentMethodButton.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
}
