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
    
    private var sessionIntent: PrimerSessionIntent = .checkout
    
    @IBOutlet weak var sessionIntentControl: UISegmentedControl!
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
//                    self.clientToken = clientToken
//
//                    var newClientSession = clientSession
//                    newClientSession.order = ClientSessionRequestBody.Order(
//                        countryCode: .fr,
//                        lineItems: [
//                            ClientSessionRequestBody.Order.LineItem(
//                                itemId: "new-fancy-shoes-\(String.randomString(length: 4))",
//                                description: "Fancy Shoes (updated)",
//                                amount: 10000,
//                                quantity: 1,
//                                discountAmount: 1999,
//                                taxAmount: 4600),
//                            ClientSessionRequestBody.Order.LineItem(
//                                itemId: "cool-hat-\(String.randomString(length: 4))",
//                                description: "Cool Hat (added)",
//                                amount: 2000,
//                                quantity: 2,
//                                discountAmount: nil,
//                                taxAmount: nil)
//                        ]
//                    )
//
//                    Networking.patchClientSession(clientToken: clientToken, requestBody: newClientSession) { newClientToken, err in

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
    
    @IBAction func onVaultManagerButtonTap(_ sender: Any) {
        let vc = MerchantHeadlesVaultManagerViewController.instantiate(settings: settings,
                                                                  clientSession: clientSession,
                                                                  clientToken: clientToken)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func onSessionIntentChange(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            // Session intent chosen is Checkout
            sessionIntent = .checkout
        case 1:
            // Session intent chosen is Vault
            sessionIntent = .vault
        default:
            // Default to Checkout
            sessionIntent = .checkout
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
        cell.accessibilityIdentifier = paymentMethod.paymentMethodType
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let paymentMethod = self.availablePaymentMethods[indexPath.row]
        let paymentMethodType = paymentMethod.paymentMethodType
        switch paymentMethodType {
        case "PAYMENT_CARD", "ADYEN_BANCONTACT_CARD":
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
        case "XENDIT_RETAIL_OUTLETS":
            let vc = MerchantHeadlessCheckoutRawRetailDataViewController.instantiate(paymentMethodType: paymentMethodType)
            self.navigationController?.pushViewController(vc, animated: true)
        case "XENDIT_OVO":
            let vc = MerchantHeadlessCheckoutRawPhoneNumberDataViewController.instantiate(paymentMethodType: paymentMethodType)
            self.navigationController?.pushViewController(vc, animated: true)
        case "NOL_PAY":
#if canImport(PrimerNolPaySDK)
            let vc = MerchantHeadlessCheckoutNolPayViewController()
            self.navigationController?.pushViewController(vc, animated: true)
#else
            break
#endif
        case "ADYEN_IDEAL":
            let vc = MerchantHeadlessCheckoutBankViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            redirectManager = try? PrimerHeadlessUniversalCheckout.NativeUIManager(paymentMethodType: paymentMethodType)
            try? redirectManager?.showPaymentMethod(intent: sessionIntent)
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
                    decisionHandler(.complete())
                    
                    let rvc = MerchantResultViewController.instantiate(checkoutData: self.checkoutData, error: self.primerError, logs: self.logs)
                    self.navigationController?.pushViewController(rvc, animated: true)
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
        print("\n\nMERCHANT APP\n\(#function)\nadditionalInfo: \(String(describing: additionalInfo))")
        self.logs.append(#function)
        DispatchQueue.main.async {
            self.hideLoadingOverlay()
        }
    }
    
    func primerHeadlessUniversalCheckoutDidEnterResumePendingWithPaymentAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo?) {
        print("\n\nMERCHANT APP\n\(#function)\nadditionalInfo: \(String(describing: additionalInfo))")
        self.logs.append(#function)
        self.hideLoadingOverlay()
    }
    
    func primerHeadlessUniversalCheckoutDidFail(withError err: Error, checkoutData: PrimerCheckoutData?) {
        print("\n\nMERCHANT APP\n\(#function)\nerror: \(err)\ncheckoutData: \(String(describing: checkoutData))")
        self.logs.append(#function)
        self.primerError = err
        self.hideLoadingOverlay()
        if navigationController?.children.last is MerchantHeadlessCheckoutBankViewController {
            navigationController?.popViewController(animated: false)
        }
        DispatchQueue.main.async {
            let rvc = MerchantResultViewController.instantiate(checkoutData: self.checkoutData, error: self.primerError, logs: self.logs)
            self.navigationController?.pushViewController(rvc, animated: true)
        }
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
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var paymentMethodLabel: UILabel!
    @IBOutlet weak var paymentMethodLogoView: UIImageView!
    
    var paymentMethod: PrimerHeadlessUniversalCheckout.PaymentMethod!
    
    func configure(paymentMethod: PrimerHeadlessUniversalCheckout.PaymentMethod) {
        self.paymentMethod = paymentMethod
        if let paymentMethodAsset = try? PrimerHeadlessUniversalCheckout.AssetsManager.getPaymentMethodAsset(for: paymentMethod.paymentMethodType) {
            
            self.stackView.backgroundColor = (paymentMethodAsset.paymentMethodBackgroundColor.colored ?? paymentMethodAsset.paymentMethodBackgroundColor.light) ?? paymentMethodAsset.paymentMethodBackgroundColor.dark
            
            if let logoImage = (paymentMethodAsset.paymentMethodLogo.colored ?? paymentMethodAsset.paymentMethodLogo.light) ?? paymentMethodAsset.paymentMethodLogo.dark {
                self.paymentMethodLogoView.isHidden = false
                self.paymentMethodLogoView.image = logoImage
                
            } else {
                self.paymentMethodLogoView.isHidden = true
                self.paymentMethodLabel.text = "Failed to find logo for \(paymentMethod.paymentMethodType)"
            }
            
            paymentMethodLabel.text = "Pay with \(paymentMethodAsset.paymentMethodName) "
            
        } else {
            self.paymentMethodLogoView.isHidden = true
            self.paymentMethodLabel.isHidden = false
            self.paymentMethodLabel.text = "Failed to find payment method asset for \(paymentMethod.paymentMethodType)"
        }
    }
}
