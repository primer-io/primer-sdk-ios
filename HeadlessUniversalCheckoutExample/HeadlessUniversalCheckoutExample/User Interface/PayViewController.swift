//
//  ViewController.swift
//  HeadlessUniversalCheckoutExample
//
//  Created by Evangelos on 16/2/22.
//

import PrimerSDK
import PromiseKit
import UIKit

class PayViewController: MyViewController, PrimerInputElementDelegate {
    
    @IBOutlet var stackView: UIStackView!
    @IBOutlet weak var amountLabel: UILabel!
    let amount = 1000
    let currency = Currency.EUR
    let countryCode = CountryCode.fr
    
    var availablePaymentMethodsTypes: [PrimerPaymentMethodType]?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.amountLabel.text = amount.toCurrencyString(currencySymbol: currency.rawValue)
        self.configurePrimerHeadlessCheckout()
    }
    
    func configurePrimerHeadlessCheckout() {
        self.showLoading()
        self.fetchClientToken { (clientToken, err) in
            if let err = err {
                self.stopLoading()
                self.showError(withMessage: err.localizedDescription)
                
            } else if let clientToken = clientToken {
                // 👇 Settings are optional, but they are needed for Apple Pay and PayPal
                let settings = PrimerSettings(
                    merchantIdentifier: "merchant.dx.team",  // 👈 Entitlement added in Xcode's settings, required for Apple Pay
                    urlScheme: "merchant://")                // 👈 URL Scheme added in Xcode's settings, required for PayPal
                
                PrimerHeadlessUniversalCheckout.current.start(withClientToken: clientToken, settings: settings, delegate: self) { paymentMethodTypes, err in
                    self.stopLoading()
                    
                    if let err = err {
                        self.showError(withMessage: err.localizedDescription)
                    } else if let paymentMethodTypes = paymentMethodTypes {
                        self.availablePaymentMethodsTypes = paymentMethodTypes
                        self.renderPaymentMethodsTypes()
                    }
                }
            }
        }
    }
    
    func fetchClientToken(completion: @escaping (String?, Error?) -> Void) {
        let networking = Networking()
        networking.requestClientSession(
            requestBody: Networking.buildClientSessionRequestBody(amount: amount, currency: currency, countryCode: countryCode),
            completion: completion)
    }
    
    func renderPaymentMethodsTypes() {
        guard let availablePaymentMethodsTypes = self.availablePaymentMethodsTypes, !availablePaymentMethodsTypes.isEmpty else {
            self.showError(withMessage: "Card payments are not available")
            return
        }

        if availablePaymentMethodsTypes.contains(.paymentCard) {
            let payByCardButton = UIButton()
            payByCardButton.translatesAutoresizingMaskIntoConstraints = false
            payByCardButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
            payByCardButton.addTarget(self, action: #selector(payWithCardButtonTapped(_:)), for: .touchUpInside)
            payByCardButton.setTitle("Pay by card", for: .normal)
            payByCardButton.setTitleColor(.systemBlue, for: .normal)
            self.stackView.addArrangedSubview(payByCardButton)
        }
        
        if availablePaymentMethodsTypes.contains(.applePay) {
            guard let applePayButton = PrimerHeadlessUniversalCheckout.makeButton(for: .applePay) else { return }
            applePayButton.addTarget(self, action: #selector(payWithApplePayButtonTapped(_:)), for: .touchUpInside)
            self.stackView.addArrangedSubview(applePayButton)
        }
        
        if availablePaymentMethodsTypes.contains(.payPal) {
            guard let payPalButton = PrimerHeadlessUniversalCheckout.makeButton(for: .payPal) else { return }
            payPalButton.addTarget(self, action: #selector(payWithPayPalButtonTapped(_:)), for: .touchUpInside)
            self.stackView.addArrangedSubview(payPalButton)
        }
    }
    
    @IBAction func payWithCardButtonTapped(_ sender: Any) {
        let cfvc = CardFormViewController.instantiate()
        self.navigationController?.pushViewController(cfvc, animated: true)
    }
    
    @IBAction func payWithApplePayButtonTapped(_ sender: Any) {
        PrimerHeadlessUniversalCheckout.current.showCheckout(for: .applePay)
    }
    
    @IBAction func payWithPayPalButtonTapped(_ sender: Any) {
        PrimerHeadlessUniversalCheckout.current.showCheckout(for: .payPal)
    }
}

extension PayViewController: PrimerHeadlessUniversalCheckoutDelegate {
    func primerHeadlessUniversalCheckoutClientSessionDidSetUpSuccessfully() {
        
    }
    
    func primerHeadlessUniversalCheckoutPreparationStarted() {
        self.showLoading()
    }
    
    func primerHeadlessUniversalCheckoutTokenizationStarted() {
        self.showLoading()
    }
    
    func primerHeadlessUniversalCheckoutPaymentMethodPresented() {
        
    }
    
    func primerHeadlessUniversalCheckoutTokenizationSucceeded(paymentMethodToken: PaymentMethodToken, resumeHandler: ResumeHandlerProtocol?) {
        self.showLoading()
        
        let networking = Networking()
        networking.createPayment(with: paymentMethodToken) { res, err in
            self.stopLoading()
            
            if let err = err {
                self.showError(withMessage: err.localizedDescription)
            } else {
                
            }
        }
    }
    
    func primerHeadlessUniversalCheckoutUniversalCheckoutDidFail(withError err: Error) {
        self.stopLoading()
        self.showError(withMessage: err.localizedDescription)
    }
    
}



