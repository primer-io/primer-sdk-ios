//
//  MerchantHeadlessVaultManagerViewController.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit
import PrimerSDK

class MerchantHeadlessVaultManagerViewController: UIViewController, PrimerHeadlessUniversalCheckoutDelegate {

    class func instantiate(settings: PrimerSettings, clientSession: ClientSessionRequestBody?, clientToken: String?) -> MerchantHeadlessVaultManagerViewController {
        let mcvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MerchantHeadlessVaultManagerViewController") as! MerchantHeadlessVaultManagerViewController
        mcvc.settings = settings
        mcvc.clientSession = clientSession
        mcvc.clientToken = clientToken
        return mcvc
    }

    var settings: PrimerSettings!
    var clientSession: ClientSessionRequestBody?
    var clientToken: String?

    var logs: [String] = []
    var primerError: Error?
    var checkoutData: PrimerCheckoutData?

    private var paymentId: String?
    private var availablePaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] = []
    private var vaultedManager: PrimerHeadlessUniversalCheckout.VaultManager?

    @IBOutlet private weak var tableView: UITableView!
    private var activityIndicator: UIActivityIndicatorView?

    override func viewDidLoad() {
        super.viewDidLoad()

        PrimerHeadlessUniversalCheckout.current.delegate = self
        PrimerHeadlessUniversalCheckout.current.uiDelegate = self
        tableView.delegate = self
        tableView.dataSource = self
        render()
    }

    private func render() {
        showLoadingOverlay()

        if let clientToken = clientToken {
            self.clientToken = clientToken
            self.startPrimerHeadlessUniversalCheckout(with: clientToken)
        } else if let clientSession = clientSession {
            Networking.requestClientSession(requestBody: clientSession,
                                            apiVersion: settings.apiVersion) { (clientToken, err) in
                if let err = err {
                    self.hideLoadingOverlay()
                    let rvc = MerchantResultViewController.instantiate(checkoutData: self.checkoutData, error: err, logs: self.logs)
                    self.navigationController?.pushViewController(rvc, animated: true)

                } else if let clientToken = clientToken {
                    self.clientToken = clientToken
                    self.startPrimerHeadlessUniversalCheckout(with: clientToken)

                } else {
                    fatalError()
                }
            }

        } else {
            fatalError()
        }
    }

    private func startPrimerHeadlessUniversalCheckout(with clientToken: String) {
        PrimerHeadlessUniversalCheckout.current.start(withClientToken: clientToken, settings: self.settings, completion: { (_, _) in
            self.vaultedManager = PrimerHeadlessUniversalCheckout.VaultManager()

            do {
                try self.vaultedManager?.configure()
                self.fetchPrimerVaultedPaymentMethods()

            } catch {
                self.hideLoadingOverlay()
                let rvc = MerchantResultViewController.instantiate(checkoutData: self.checkoutData, error: error, logs: self.logs)
                self.navigationController?.pushViewController(rvc, animated: true)
            }
        })
    }

    private func fetchPrimerVaultedPaymentMethods() {
        self.vaultedManager?.fetchVaultedPaymentMethods { vaultedPaymentMethods, err in
            self.hideLoadingOverlay()

            if let err = err {
                let rvc = MerchantResultViewController.instantiate(checkoutData: self.checkoutData, error: err, logs: self.logs)
                self.navigationController?.pushViewController(rvc, animated: true)

            } else if let vaultedPaymentMethods = vaultedPaymentMethods {
                self.availablePaymentMethods = self.filterInvalidVaultedPaymentMethods(vaultedPaymentMethods: vaultedPaymentMethods)
                self.tableView.reloadData()
            }
        }
    }

    private func filterInvalidVaultedPaymentMethods(vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod]) -> [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] {
        // Quick filter validating expiry year
        let expiredVaultedCards = vaultedPaymentMethods.filter({ $0.paymentMethodType == "PAYMENT_CARD" && Int($0.paymentInstrumentData.expirationYear ?? "") ?? 0 < 2023 })
        let expiredVaultedCardsIds: [String] = expiredVaultedCards.compactMap({ $0.id })
        // To be returned when not testing CVV recapture
        return vaultedPaymentMethods.filter({ !expiredVaultedCardsIds.contains($0.id) })
        // Uncomment this line and comment out the above, when you are not testing CVV recapture
        // return vaultedPaymentMethods.filter({ $0.paymentInstrumentData.first6Digits == "411111" && $0.paymentInstrumentData.expirationMonth == "03" && $0.paymentInstrumentData.expirationYear == "2030" })
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

    private func showAlert(title: String, message: String, okHandler: (() -> Void)? = nil, cancelHandler: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in okHandler?() }
        okAction.accessibilityIdentifier = AccessibilityIdentifier.StripeAchUserDetailsComponent.acceptMandateButton.rawValue
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in cancelHandler?() }
        cancelAction.accessibilityIdentifier = AccessibilityIdentifier.StripeAchUserDetailsComponent.declineMandateButton.rawValue
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
}

extension MerchantHeadlessVaultManagerViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.availablePaymentMethods.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let paymentMethod = self.availablePaymentMethods[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "MerchantVaultedPaymentMethodCell", for: indexPath) as! MerchantVaultedPaymentMethodCell

        cell.configure(paymentMethod: paymentMethod)
        cell.accessibilityIdentifier = paymentMethod.paymentMethodType
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showLoadingOverlay()
        let vaultedPaymentMethod = self.availablePaymentMethods[indexPath.row]
        if vaultedPaymentMethod.paymentMethodType == "PAYMENT_CARD" {
            self.vaultedManager?.startPaymentFlow(vaultedPaymentMethodId: vaultedPaymentMethod.id, vaultedPaymentMethodAdditionalData: PrimerVaultedCardAdditionalData(cvv: "737"))
            return
        }

        self.vaultedManager?.startPaymentFlow(vaultedPaymentMethodId: vaultedPaymentMethod.id)
    }
}

// MARK: Manual Payment Handling

extension MerchantHeadlessVaultManagerViewController {

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

            let rvc = MerchantResultViewController.instantiate(checkoutData: nil, error: self.primerError, logs: self.logs)
            self.navigationController?.pushViewController(rvc, animated: true)
        }
    }
}

// MARK: Common

extension MerchantHeadlessVaultManagerViewController {

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

extension MerchantHeadlessVaultManagerViewController: PrimerHeadlessUniversalCheckoutUIDelegate {

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

class MerchantVaultedPaymentMethodCell: UITableViewCell {

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var paymentMethodLabel: UILabel!
    @IBOutlet weak var paymentMethodLogoView: UIImageView!

    var paymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod!

    func configure(paymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod) {
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

            if paymentMethod.paymentMethodType == "STRIPE_ACH" {
                paymentMethodLabel.text = "Pay with ACH \(paymentMethod.paymentInstrumentData.bankName ?? "-") **** \(paymentMethod.paymentInstrumentData.accountNumberLast4Digits ?? "-")"
            } else {
                paymentMethodLabel.text = "Pay with \(paymentMethodAsset.paymentMethodName) "
            }
        } else {
            self.paymentMethodLogoView.isHidden = true
            self.paymentMethodLabel.isHidden = false
            self.paymentMethodLabel.text = "Failed to find payment method asset for \(paymentMethod.paymentMethodType)"
        }
    }
}
