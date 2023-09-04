//
//  MerchantPaymentMethodsViewController.swift
//  PrimerSDK_Example
//
//  Created by Evangelos on 2/2/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import PrimerSDK
import UIKit

class MerchantPaymentMethodsViewController: UIViewController {
    
    static func instantiate(
        amount: Int,
        currency: Currency,
        countryCode: CountryCode,
        customerId: String?,
        phoneNumber: String?
    ) -> MerchantPaymentMethodsViewController {
        let mpmvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MerchantPaymentMethodsViewController") as! MerchantPaymentMethodsViewController
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
    
    private var clientToken: String?
    
    
    @IBOutlet weak var tableView: UITableView!
    var activityIndicator: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PrimerHeadlessUniversalCheckout.current.delegate = self
        
        self.activityIndicator = UIActivityIndicatorView(frame: self.view.bounds)
        self.view.addSubview(self.activityIndicator!)
        self.activityIndicator?.backgroundColor = .black.withAlphaComponent(0.2)
        self.activityIndicator?.color = .black
        self.activityIndicator?.startAnimating()
        
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
                
                self.clientToken = clientToken
                
                PrimerHeadlessUniversalCheckout.current.start(withClientToken: clientToken, settings: settings, completion: { (pms, err) in
                    DispatchQueue.main.async {
                        self.activityIndicator?.stopAnimating()
                        self.activityIndicator?.removeFromSuperview()
                        self.activityIndicator = nil
                        
                        self.availablePaymentMethods = (pms ?? []).map { $0.paymentMethodType }
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

extension MerchantPaymentMethodsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.availablePaymentMethods.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let paymentMethod = self.availablePaymentMethods[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "MerchantPaymentMethodCell", for: indexPath) as! MerchantPaymentMethodCell
        cell.configure(paymentMethodType: paymentMethod, clientToken: clientToken)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let paymentMethodType = self.availablePaymentMethods[indexPath.row]
        if paymentMethodType == "PAYMENT_CARD" {
            let mcfvc = MerchantCardFormViewController()
            self.navigationController?.pushViewController(mcfvc, animated: true)
        } else {
            // JN TODO
//            PrimerHeadlessUniversalCheckout.makeButton(for: "PAYPAL")
//            PrimerHeadlessUniversalCheckout.current.showPaymentMethod(paymentMethodType)
        }
    }
}

extension MerchantPaymentMethodsViewController: PrimerHeadlessUniversalCheckoutDelegate {

    func primerHeadlessUniversalCheckoutDidLoadAvailablePaymentMethods(_ paymentMethodTypes: [String]) {
        print("\n\n🤯🤯🤯 \(#function)")
    }
    
    func primerHeadlessUniversalCheckoutPreparationDidStart(for paymentMethodType: String) {
        print("\n\n🤯🤯🤯 \(#function)")
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
                            let rvc = HUCResultViewController.instantiate(data: [data])
                            self.navigationController?.pushViewController(rvc, animated: true)
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
    
    func primerHeadlessUniversalCheckoutDidReceiveAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo?) {
        print("\n\n🤯🤯🤯 \(#function)\nadditionalInfo: \(additionalInfo)")
        DispatchQueue.main.async {
            self.hideLoadingOverlay()
        }
    }
    
    func primerHeadlessUniversalCheckoutDidEnterResumePendingWithPaymentAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo?) {
        print("\n\n🤯🤯🤯 \(#function)\nadditionalInfo: \(additionalInfo)")
        
        DispatchQueue.main.async {
            self.hideLoadingOverlay()
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

class MerchantPaymentMethodCell: UITableViewCell {
    
    private var paymentMethodType: String?
    private var clientToken: String?
    
    @IBOutlet weak var paymentMethodLabel: UILabel!
    @IBOutlet weak var buttonContainerView: UIView!
    
    func configure(paymentMethodType: String, clientToken: String?) {
        self.paymentMethodType = paymentMethodType
        self.clientToken = clientToken
        
        paymentMethodLabel.text = paymentMethodType
        
        let button = UIButton()
        button.setTitle("Open", for: .normal)
        button.addTarget(self, action: #selector(didTap), for: .touchUpInside)
        button.setTitleColor(.blue, for: .normal)
        buttonContainerView.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        buttonContainerView.addConstraints([
            button.trailingAnchor.constraint(equalTo: buttonContainerView.trailingAnchor),
            button.topAnchor.constraint(equalTo: buttonContainerView.topAnchor),
            button.bottomAnchor.constraint(equalTo: buttonContainerView.bottomAnchor)
        ])
        buttonContainerView.updateConstraints()
    }
    
    @objc func didTap(sender: UIButton!) {
        guard let paymentMethodType = paymentMethodType else {
            print("\n\n🚨 No payment method set - failed to open payment method")
            return
        }
        guard let clientToken = clientToken else {
            print("\n\n🚨 No client session token available - failed to open payment method")
            return
        }
        
        Primer.shared.showPaymentMethod(paymentMethodType, intent: .checkout, clientToken: clientToken)
    }
    
}
