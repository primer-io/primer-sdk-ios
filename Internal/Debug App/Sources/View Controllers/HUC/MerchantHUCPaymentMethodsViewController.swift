//
//  MerchantPaymentMethodsViewController.swift
//  PrimerSDK_Example
//
//  Created by Evangelos on 2/2/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import PrimerSDK
import UIKit

class MerchantHUCPaymentMethodsViewController: UIViewController, PrimerHeadlessUniversalCheckoutDelegate {
    
    static func instantiate() -> MerchantHUCPaymentMethodsViewController {
        let mpmvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MerchantHUCPaymentMethodsViewController") as! MerchantHUCPaymentMethodsViewController
        return mpmvc
    }

    var amount: Int!
    var currency: Currency!
    var countryCode: CountryCode!
    var availablePaymentMethods: [PrimerHeadlessUniversalCheckoutPaymentMethod] = []
    var customerId: String?
    var phoneNumber: String?
    private var paymentId: String?
    
    var availablePaymentMethods: [String] = []
    var paymentId: String?
    
    var checkoutData: [String] = []
    var primerError: Error?
    var logs: [String] = []
    
    @IBOutlet weak var tableView: UITableView!
    var activityIndicator: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PrimerHeadlessUniversalCheckout.current.delegate = self
        PrimerHeadlessUniversalCheckout.current.uiDelegate = self
        
        self.activityIndicator = UIActivityIndicatorView(frame: self.view.bounds)
        self.view.addSubview(self.activityIndicator!)
        self.activityIndicator?.backgroundColor = .black.withAlphaComponent(0.2)
        self.activityIndicator?.color = .black
        self.activityIndicator?.startAnimating()
        
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
                        applePayOptions: PrimerApplePayOptions(merchantIdentifier: "merchant.dx.team", merchantName: "Primer Merchant", isCaptureBillingAddressEnabled: false)
                    )
                )
                
                PrimerHeadlessUniversalCheckout.current.start(withClientToken: clientToken, settings: settings, completion: { (pms, err) in
                    DispatchQueue.main.async {
                        self.activityIndicator?.stopAnimating()
                        self.activityIndicator?.removeFromSuperview()
                        self.activityIndicator = nil
                        
                        self.availablePaymentMethods = pms ?? []
                        self.tableView.reloadData()
                    }
                })
            }
        }
    }
    
    // MARK: - HELPERS
    
    private func showLoadingOverlay() {
        self.activityIndicator = UIActivityIndicatorView(frame: self.view.bounds)
        self.view.addSubview(self.activityIndicator!)
        self.activityIndicator?.backgroundColor = .black.withAlphaComponent(0.2)
        self.activityIndicator?.color = .black
        self.activityIndicator?.startAnimating()
    }
    
    private func hideLoadingOverlay() {
        self.activityIndicator?.stopAnimating()
        self.activityIndicator?.removeFromSuperview()
        self.activityIndicator = nil
    }
}

extension MerchantHUCPaymentMethodsViewController: UITableViewDataSource, UITableViewDelegate {
    
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
        let paymentMethodType = self.availablePaymentMethods[indexPath.row]
        if paymentMethodType == "PAYMENT_CARD" ||
            paymentMethodType == "ADYEN_BANCONTACT_CARD"
        {
            let alert = UIAlertController(title: "", message: "Select Implementation", preferredStyle: .actionSheet)
            
            let rawDataAlertAction = UIAlertAction(title: "Raw Data", style: .default , handler:{ (UIAlertAction)in
                let vc = MerchantHUCRawDataViewController.instantiate(paymentMethodType: paymentMethodType)
                self.navigationController?.pushViewController(vc, animated: true)
            })
            rawDataAlertAction.accessibilityIdentifier = "raw_data_huc_alert_action"
            
            let cardComponentsAlertAction = UIAlertAction(title: "Card Components", style: .default , handler:{ (UIAlertAction)in
                let vc = MerchantHUCCardComponentsViewController.instantiate(paymentMethodType: paymentMethodType)
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
            let vc = MerchantHUCRawRetailDataViewController.instantiate(paymentMethodType: paymentMethodType)
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            PrimerHeadlessUniversalCheckout.current.showPaymentMethod(paymentMethodType)
        }
    }
}

extension MerchantPaymentMethodsViewController: PrimerCheckoutEventsDelegate, PrimerUIEventsDelegate {

// MARK: - PRIMER HEADLESS UNIVERSAL CHECKOUT DELEGATE

// MARK: Auto Payment Handling

extension MerchantHUCPaymentMethodsViewController {
    
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

extension MerchantHUCPaymentMethodsViewController {
    
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
            
            if let clientToken = res?.requiredAction?.clientToken {
                decisionHandler(.continueWithNewClientToken(clientToken))
            } else {
                print("Payment has been resumed")
            }
            
            let rvc = MerchantResultViewController.instantiate(checkoutData: self.checkoutData, error: self.primerError, logs: self.logs)
            self.navigationController?.pushViewController(rvc, animated: true)
        }
    }
}

// MARK: Common

extension MerchantHUCPaymentMethodsViewController {
    
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

class MerchantPaymentMethodCell: UITableViewCell {
    
    @IBOutlet weak var paymentMethodLabel: UILabel!
    @IBOutlet weak var buttonContainerView: UIView!
    
    var paymentMethod: PrimerHeadlessUniversalCheckoutPaymentMethod!
    
    func configure(paymentMethod: PrimerHeadlessUniversalCheckoutPaymentMethod) {
        self.paymentMethod = paymentMethod
        paymentMethodLabel.text = paymentMethod.paymentMethodType
        
        let paymentMethodAsset = try? PrimerAssetsManager.getPaymentMethodAsset(for: paymentMethod.paymentMethodType)
        
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
        
        paymentMethodButton.backgroundColor = paymentMethodAsset?.paymentMethodBackgroundColor.colored
        paymentMethodButton.setTitle(paymentMethodAsset?.paymentMethodType, for: .normal)
        paymentMethodButton.setImage(paymentMethodAsset?.paymentMethodLogo.colored, for: .normal)
        paymentMethodButton.setTitleColor(.black, for: .normal)

        paymentMethodButton.translatesAutoresizingMaskIntoConstraints = false
        paymentMethodButton.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        paymentMethodButton.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        paymentMethodButton.topAnchor.constraint(equalTo: topAnchor).isActive = true
        paymentMethodButton.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        paymentMethodButton.addTarget(self, action: #selector(paymentButtonTapped), for: .touchUpInside)
    }
    
    @IBAction func paymentButtonTapped(_ sender: UIButton) {
        let redirectPaymentMethodManager = PrimerRedirectPaymentMethodManager(paymentMethodType: self.paymentMethod.paymentMethodType)
    }
}
