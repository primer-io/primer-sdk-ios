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
    var manualHandlingCheckoutData: PrimerCheckoutData?
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
        setupSessionLogic()
    }

    @IBAction func onVaultManagerButtonTap(_ sender: Any) {
        let vc = MerchantHeadlessVaultManagerViewController.instantiate(settings: settings,
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
    
    private func resetPaymentResultState() {
        logs.removeAll(keepingCapacity: false)
        primerError = nil
        checkoutData = nil
        manualHandlingCheckoutData = nil
    }
    
    private func presentResultsVC() {
        let resultsCheckoutData = manualHandlingCheckoutData != nil ? manualHandlingCheckoutData : checkoutData
        let rvc = MerchantResultViewController.instantiate(checkoutData: resultsCheckoutData, error: primerError, logs: logs)
        self.navigationController?.pushViewController(rvc, animated: true)
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
        resetPaymentResultState()
        let paymentMethodType = paymentMethod.paymentMethodType
        switch paymentMethodType {
        case "PAYMENT_CARD", "ADYEN_BANCONTACT_CARD":
            let alert = UIAlertController(title: "", message: "Select Implementation", preferredStyle: .actionSheet)

            let rawDataAlertAction = UIAlertAction(title: "Raw Data", style: .default, handler: { (_)in
                let vc = MerchantHeadlessCheckoutRawDataViewController.instantiate(paymentMethodType: paymentMethodType)
                self.navigationController?.pushViewController(vc, animated: true)
            })
            rawDataAlertAction.accessibilityIdentifier = "raw_data_huc_alert_action_\(paymentMethodType)"

            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            cancelAction.accessibilityIdentifier = "cancel_huc_alert_action"

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
        case "KLARNA":
            #if canImport(PrimerKlarnaSDK)
            let vc = MerchantHeadlessCheckoutKlarnaViewController(sessionIntent: sessionIntent)
            self.navigationController?.pushViewController(vc, animated: true)
            #else
            break
            #endif
        case "STRIPE_ACH":
            #if canImport(PrimerStripeSDK)
            let vc = MerchantHeadlessCheckoutStripeAchViewController()
            self.navigationController?.pushViewController(vc, animated: true)
            #else
            break
            #endif
        default:
            do {
                redirectManager = try PrimerHeadlessUniversalCheckout.NativeUIManager(paymentMethodType: paymentMethodType)
                try redirectManager?.showPaymentMethod(intent: sessionIntent)
            } catch {
                print("\n\nMERCHANT APP\n\(#function)\nerror: \(error)")
            }
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

        if let lastViewController = navigationController?.children.last {
            if lastViewController is MerchantHeadlessCheckoutKlarnaViewController {
                navigationController?.popViewController(animated: false)
            }
        }

        presentResultsVC()
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
                    
                    if let lastViewController = self.navigationController?.children.last {
                        if lastViewController is MerchantHeadlessCheckoutKlarnaViewController {
                            self.manualHandlingCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(id: res.id,
                                                                                                      orderId: res.orderId,
                                                                                                      paymentFailureReason: nil))
                        } else {
                            self.presentResultsVC()
                        }
                    } else {
                        self.presentResultsVC()
                    }
                }

            } else {
                assert(true)
            }
        }
    }

    func primerHeadlessUniversalCheckoutDidResumeWith(_ resumeToken: String, decisionHandler: @escaping (PrimerHeadlessUniversalCheckoutResumeDecision) -> Void) {
        print("\n\nMERCHANT APP\n\(#function)\nresumeToken: \(resumeToken)")
        self.logs.append(#function)

        Networking.resumePayment(self.paymentId!, withToken: resumeToken) { (res, _) in
            DispatchQueue.main.async {
                self.hideLoadingOverlay()
            }

            if let clientToken = res?.requiredAction?.clientToken {
                decisionHandler(.continueWithNewClientToken(clientToken))
            } else {
                print("Payment has been resumed")
                decisionHandler(.complete())
            }

            self.presentResultsVC()
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
        self.checkoutData = checkoutData
        self.hideLoadingOverlay()

        if let lastViewController = navigationController?.children.last {
            if lastViewController is MerchantHeadlessCheckoutBankViewController ||
               lastViewController is MerchantHeadlessCheckoutKlarnaViewController {
                navigationController?.popViewController(animated: false)
            }
        }

        DispatchQueue.main.async {
            self.presentResultsVC()
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

    func primerHeadlessUniversalCheckoutUIDidDismissPaymentMethod() {
        print("\n\nMERCHANT APP\n\(#function)\nUIDidDismissPaymentMethod")
        self.logs.append(#function)
    }
}

extension MerchantHeadlessCheckoutAvailablePaymentMethodsViewController {

    private func setupSessionLogic() {
        if let clientToken = clientToken {
            PrimerHeadlessUniversalCheckout.current.start(withClientToken: clientToken, settings: self.settings, completion: { (pms, _) in
                self.hideLoadingOverlay()

                DispatchQueue.main.async {
                    self.availablePaymentMethods = pms ?? []
                    self.tableView.reloadData()
                }
            })

        } else if let clientSession = clientSession {
            Networking.requestClientSession(requestBody: clientSession,
                                            apiVersion: settings.apiVersion) { (clientToken, err) in
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

                    PrimerHeadlessUniversalCheckout.current.start(withClientToken: clientToken, settings: self.settings, completion: { (pms, _) in
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

            paymentMethodLabel.text = "Pay with \(paymentMethodAsset.paymentMethodName.prefix(15))... "
            paymentMethodLabel.lineBreakMode = .byTruncatingTail

        } else {
            self.paymentMethodLogoView.isHidden = true
            self.paymentMethodLabel.isHidden = false
            self.paymentMethodLabel.text = "Failed to find payment method asset for \(paymentMethod.paymentMethodType)"
        }
    }
}
