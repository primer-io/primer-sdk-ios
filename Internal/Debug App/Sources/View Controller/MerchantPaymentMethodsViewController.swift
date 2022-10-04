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
    var availablePaymentMethods: [PrimerHeadlessUniversalCheckout.PaymentMethod] = []
    var customerId: String?
    var phoneNumber: String?
    private var paymentId: String?
    
    var redirectManager: PrimerPaymentMethodNativeUIManager?
    

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

extension MerchantPaymentMethodsViewController: UITableViewDataSource, UITableViewDelegate {
    
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
        if paymentMethodType == "PAYMENT_CARD" {
            let mcfvc = MerchantCardFormViewController()
            self.navigationController?.pushViewController(mcfvc, animated: true)
        } else {
            redirectManager = try? PrimerPaymentMethodNativeUIManager(paymentMethodType: paymentMethodType)
            try? redirectManager?.showPaymentMethod(intent: .checkout)
        }
    }
}

extension MerchantPaymentMethodsViewController: PrimerCheckoutEventsDelegate {

    func primerHeadlessUniversalCheckoutDidLoadAvailablePaymentMethods(_ paymentMethods: [PrimerHeadlessUniversalCheckout.PaymentMethod]) {
        print("🤯🤯🤯 \(#function)\npaymentMethods: \(paymentMethods)")
    }
    
    func primerHeadlessUniversalCheckoutTokenizationDidStart(for paymentMethodType: String) {
        print("\n\n🤯🤯🤯 \(#function)\npaymentMethodType: \(paymentMethodType)")
    }
    
    func primerHeadlessUniversalCheckoutDidTokenizePaymentMethod(_ paymentMethodTokenData: PrimerPaymentMethodTokenData, decisionHandler: @escaping (PrimerHeadlessUniversalCheckoutResumeDecision) -> Void) {
        print("\n\n🤯🤯🤯 \(#function)\npaymentMethodTokenData: \(paymentMethodTokenData)")
        
        Networking.createPayment(with: paymentMethodTokenData) { (res, err) in
            if let err = err {
                DispatchQueue.main.async {
                    self.hideLoadingOverlay()
                    decisionHandler(.complete())
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
        print("\n\n🤯🤯🤯 \(#function)\nresumeToken: \(resumeToken)")
        
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

extension MerchantPaymentMethodsViewController: PrimerUIEventsDelegate {
    
    func primerHeadlessUniversalCheckoutPreparationDidStart(for paymentMethodType: String) {
        print("\n\n🤯🤯🤯 \(#function)")
        self.showLoadingOverlay()
    }
    
    func primerHeadlessUniversalCheckoutPaymentMethodDidShow(for paymentMethodType: String) {
        print("\n\n🤯🤯🤯 \(#function)\npaymentMethodType: \(paymentMethodType)")
    }
}

class MerchantPaymentMethodCell: UITableViewCell {
    
    @IBOutlet weak var paymentMethodLabel: UILabel!
    @IBOutlet weak var buttonContainerView: UIView!
    
    var paymentMethod: PrimerHeadlessUniversalCheckout.PaymentMethod!
    
    func configure(paymentMethod: PrimerHeadlessUniversalCheckout.PaymentMethod) {
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
    }
}
