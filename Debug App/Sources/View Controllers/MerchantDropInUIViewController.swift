//
//  MerchantDropInUIViewController.swift
//  PrimerSDK_Example
//
//  Created by Evangelos Pittas on 12/4/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import PrimerSDK
import UIKit

class MerchantDropInUIViewController: UIViewController, PrimerDelegate {

    class func instantiate(settings: PrimerSettings,
                           clientSession: ClientSessionRequestBody?,
                           clientToken: String?) -> MerchantDropInUIViewController {
        let mcvc = UIStoryboard(name: "Main",
                                bundle: nil).instantiateViewController(withIdentifier: "MerchantCheckoutViewController") as! MerchantDropInUIViewController
        mcvc.settings = settings
        mcvc.clientSession = clientSession
        mcvc.clientToken = clientToken
        return mcvc
    }

    var threeDSAlert: UIAlertController?

    var checkoutData: PrimerCheckoutData?
    var primerError: Error?
    var logs: [String] = []
    var transactionResponse: TransactionResponse?

    var settings: PrimerSettings!
    var clientSession: ClientSessionRequestBody?
    var clientToken: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Primer [\(environment.rawValue)]"
        Primer.shared.configure(settings: settings, delegate: self)
    }

    private var paymentMethodTypeSessionIntent = PrimerSessionIntent.checkout

    // MARK: - OUTLETS
    @IBOutlet weak var paymentMethodTypeSessionIntentControl: UISegmentedControl!
    @IBOutlet weak var paymentMethodTypeTextfield: UITextField!
    @IBOutlet weak var showPaymentMethodButton: UIButton!

    // MARK: - ACTIONS

    @IBAction func openVaultButtonTapped(_ sender: Any) {
        print("\n\nMERCHANT APP\n\(#function)\n")
        self.logs.append(#function)

        if let clientToken = clientToken {
            Primer.shared.showVaultManager(clientToken: clientToken)
        } else if let clientSession = clientSession {
            Networking.requestClientSession(requestBody: clientSession) { (clientToken, err) in
                if let err = err {
                    print(err)
                    let merchantErr = NSError(domain: "merchant-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch client token"])
                    print(merchantErr)
                } else if let clientToken = clientToken {
                    Primer.shared.showVaultManager(clientToken: clientToken)
                }
            }
        } else {
            fatalError()
        }
    }

    @IBAction func openUniversalCheckoutTapped(_ sender: Any) {
        print("\n\nMERCHANT APP\n\(#function)\n")
        self.logs.append(#function)

        if let clientToken = clientToken {
            Primer.shared.showUniversalCheckout(clientToken: clientToken)

        } else if let clientSession = clientSession {
            Networking.requestClientSession(requestBody: clientSession) { (clientToken, err) in
                if let err = err {
                    print(err)
                    let merchantErr = NSError(domain: "merchant-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch client token"])
                    print(merchantErr)
                } else if let clientToken = clientToken {
                    Primer.shared.showUniversalCheckout(clientToken: clientToken)
                }
            }
        } else {
            fatalError()
        }
    }

    @IBAction func showPaymentMethodButtonTapped(_ sender: Any) {
        guard let paymentMethod = paymentMethodTypeTextfield.text else {
            return
        }

        print("\n\nMERCHANT APP\n\(#function)\n")
        self.logs.append(#function)

        if let clientToken = clientToken {
            Primer.shared.showPaymentMethod(paymentMethod,
                                            intent: paymentMethodTypeSessionIntent,
                                            clientToken: clientToken)
        } else if let clientSession = clientSession {
            Networking.requestClientSession(requestBody: clientSession) { (clientToken, err) in
                if let err = err {
                    print(err)
                    let merchantErr = NSError(domain: "merchant-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch client token"])
                    print(merchantErr)
                } else if let clientToken = clientToken {
                    Primer.shared.showPaymentMethod(paymentMethod,
                                                    intent: self.paymentMethodTypeSessionIntent,
                                                    clientToken: clientToken)
                }
            }
        }
    }

    @IBAction func paymentMethodSessionIntentChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            paymentMethodTypeSessionIntent = .checkout
        case 1:
            paymentMethodTypeSessionIntent = .vault
        default:
            paymentMethodTypeSessionIntent = .checkout
        }
    }

    @IBAction func paymentMethodTypeEditingDidChange(_ sender: UITextField) {
        if let text = sender.text {
            showPaymentMethodButton.isHidden = text.isEmpty
        }
    }

}

// MARK: - PRIMER DELEGATE

// MARK: Auto Payment Handling

extension MerchantDropInUIViewController {

    func primerDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) {
        print("\n\nMERCHANT APP\n\(#function)\nPayment Success: \(data)\n")
        self.checkoutData = data
        self.logs.append(#function)
    }
}

// MARK: Manual Payment Handling

extension MerchantDropInUIViewController {

    func primerDidTokenizePaymentMethod(_ paymentMethodTokenData: PrimerPaymentMethodTokenData, decisionHandler: @escaping (PrimerResumeDecision) -> Void) {
        print("\n\nMERCHANT APP\n\(#function)\npaymentMethodTokenData: \(paymentMethodTokenData)")
        self.logs.append(#function)

        if paymentMethodTokenData.paymentInstrumentType == .paymentCard,
           let threeDSecureAuthentication = paymentMethodTokenData.threeDSecureAuthentication,
           threeDSecureAuthentication.responseCode != ThreeDS.ResponseCode.notPerformed && threeDSecureAuthentication.responseCode != ThreeDS.ResponseCode.authSuccess {
            var message: String = ""

            if let reasonCode = threeDSecureAuthentication.reasonCode {
                message += "[\(reasonCode)] "
            }

            if let reasonText = threeDSecureAuthentication.reasonText {
                message += reasonText
            }

            threeDSAlert = UIAlertController(title: "3DS Error", message: message, preferredStyle: .alert)
            threeDSAlert?.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
                self?.threeDSAlert = nil
            }))
        }

        if !performPaymentAfterVaulting {
            decisionHandler(.succeed())
            return
        }

        Networking.createPayment(with: paymentMethodTokenData) { res, err in
            if let err = err {
                self.showErrorMessage(err.localizedDescription)
                decisionHandler(.fail(withErrorMessage: "Oh no, something went wrong creating the payment..."))

            } else if let res = res {
                self.checkoutData = PrimerCheckoutData(
                    payment: PrimerCheckoutDataPayment(
                        id: res.id,
                        orderId: res.orderId,
                        paymentFailureReason: nil))

                if res.status == .declined {
                    decisionHandler(.fail(withErrorMessage: "Oh no, payment was declined :("))
                    return
                }

                guard let requiredAction = res.requiredAction else {
                    decisionHandler(.succeed())
                    return
                }

                guard let dateStr = res.dateStr else {
                    decisionHandler(.succeed())
                    return
                }

                self.transactionResponse = TransactionResponse(id: res.id!, date: dateStr, status: res.status.rawValue, requiredAction: requiredAction)

                if res.status == .pending {
                    decisionHandler(.continueWithNewClientToken(requiredAction.clientToken))
                } else {
                    decisionHandler(.succeed())
                }

            } else {
                assert(true)
            }
        }
    }

    func primerDidResumeWith(_ resumeToken: String, decisionHandler: @escaping (PrimerResumeDecision) -> Void) {
        print("\n\nMERCHANT APP\n\(#function)\nresumeToken: \(resumeToken)")
        self.logs.append(#function)

        guard let transactionResponse = transactionResponse else {
            decisionHandler(.fail(withErrorMessage: "Oh no, something went wrong parsing the response..."))
            return
        }

        Networking.resumePayment(transactionResponse.id, withToken: resumeToken) { res, err in
            if let err = err {
                self.showErrorMessage(err.localizedDescription)
                decisionHandler(.fail(withErrorMessage: "Oh no, something went wrong creating the payment..."))

            } else if let res = res {
                if res.status == .declined {
                    decisionHandler(.fail(withErrorMessage: "Oh no, payment was declined :("))
                } else {
                    decisionHandler(.succeed())
                }
            }
        }
    }
}

// MARK: Common

extension MerchantDropInUIViewController {

    func primerClientSessionWillUpdate() {
        print("\n\nMERCHANT APP\n\(#function)")
        self.logs.append(#function)
    }

    func primerClientSessionDidUpdate(_ clientSession: PrimerClientSession) {
        print("\n\nMERCHANT APP\n\(#function)")
        self.logs.append(#function)
    }

    func primerWillCreatePaymentWithData(_ data: PrimerCheckoutPaymentMethodData, decisionHandler: @escaping (PrimerPaymentCreationDecision) -> Void) {
        print("\n\nMERCHANT APP\n\(#function)\nData: \(data)")
        self.logs.append(#function)
        decisionHandler(.continuePaymentCreation())
    }

    func primerDidEnterResumePendingWithPaymentAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo?) {
        print("\n\nMERCHANT APP\n\(#function)\nadditionalInfo: \(String(describing: additionalInfo))")
        self.logs.append(#function)
    }

    func primerDidFailWithError(_ error: Error, data: PrimerCheckoutData?, decisionHandler: @escaping ((PrimerErrorDecision) -> Void)) {
        print("\n\nMERCHANT APP\n\(#function)\nError: \(error)")
        self.primerError = error
        self.logs.append(#function)

        let message = "Merchant App | ERROR: \(error.localizedDescription)"
        decisionHandler(.fail(withErrorMessage: message))
    }

    func primerDidDismiss() {
        print("\n\nMERCHANT APP\n\(#function)")
        self.logs.append(#function)

        if let threeDSAlert = self.threeDSAlert {
            self.present(threeDSAlert, animated: true, completion: nil)
        }

        let rvc = MerchantResultViewController.instantiate(checkoutData: self.checkoutData, error: self.primerError, logs: self.logs)
        self.navigationController?.pushViewController(rvc, animated: true)
    }
}
