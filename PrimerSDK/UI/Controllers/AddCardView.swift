//
//  AddCardView.swift
//  DemoPrimerSDK
//
//  Created by Carl Eriksson on 06/12/2020.
//

import UIKit

class AddCardViewController: UIViewController {
    
    private let bkgColor = UIColor(red: 246.0/255.0, green: 246.0/255.0, blue: 246.0/255.0, alpha: 1)
    
    var cardFormView = CardFormView()
    var checkout: UniversalCheckoutProtocol
    var reloadDelegate: ReloadDelegate?
    var spinner = UIActivityIndicatorView()
    
    init(_ checkout: UniversalCheckoutProtocol) {
        self.checkout = checkout
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        self.view.backgroundColor = self.bkgColor
        
        addSpinner()
        
        checkout.loadCheckoutConfig({
            result in
            
            switch result {
            case .failure(let error):
                print("failure!", error)
            case .success:
                DispatchQueue.main.async {
                    self.removeSpinner()
                    
                    self.view.addSubview(self.cardFormView)
                    self.cardFormView.pin(to: self.view)
                    self.cardFormView.cardTF.addTarget(self, action: #selector(self.textFieldDidChange2), for: .editingChanged)
                    self.cardFormView.expTF.addTarget(self, action: #selector(self.textFieldDidChange), for: .editingChanged)
                    self.cardFormView.submitButton.addTarget(self, action: #selector(self.authorize), for: .touchUpInside)
                    self.cardFormView.scannerButton.addTarget(self, action: #selector(self.showScanner), for: .touchUpInside)
                    
                    if (self.checkout.uxMode == UXMode.CHECKOUT) {
                        self.cardFormView.submitButton.setTitle("Pay", for: .normal)
                    }
                    
//                    self.view.backgroundColor = self.bkgColor
                    self.hideKeyboardWhenTappedAround()
                    NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
                    NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
                }
            }
        })
    }
    
    let dateMask = Veil(pattern: "##/##")
    
    @objc func textFieldDidChange(_ sender: UITextField) {
        guard let currentText = sender.text else  { return }
        
        sender.text = dateMask.mask(input: currentText, exhaustive: false)
    }
    
    let dateMask2 = Veil(pattern: "#### #### #### ####")
    
    @objc func textFieldDidChange2(_ sender: UITextField) {
        guard let currentText = sender.text else  {
            return
        }
        
        sender.text = dateMask2.mask(input: currentText, exhaustive: false)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        print(UIScreen.main.bounds.height)
        print(view.frame.origin.y)
        print(view.frame.height)
        print(UIScreen.main.bounds.height * 0.4)
        print((UIScreen.main.bounds.height - view.frame.height))
        let height = UIScreen.main.bounds.height - view.frame.height
        print(height.rounded())
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y.rounded() == height.rounded() {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        let height = UIScreen.main.bounds.height - view.frame.height
        if self.view.frame.origin.y.rounded() != height.rounded() {
            self.view.frame.origin.y = height.rounded()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func luhnCheck(_ number: String) -> Bool {
        var sum = 0
        let digitStrings = number.reversed().map { String($0) }
        
        for tuple in digitStrings.enumerated() {
            if let digit = Int(tuple.element) {
                let odd = tuple.offset % 2 == 1
                
                switch (odd, digit) {
                case (true, 9):
                    sum += 9
                case (true, 0...8):
                    sum += (digit * 2) % 9
                default:
                    sum += digit
                }
            } else {
                return false
            }
        }
        return sum % 10 == 0
    }
    
    @objc func authorize() {
        
        // validation
        // TODO: refactor and improve
        
        let name = cardFormView.nameTF.text!
        
        if (name.count < 1) {
            cardFormView.nameTF.textColor = .red
            return
        } else {
            cardFormView.nameTF.textColor = .black
        }
        
        func isStringContainsOnlyNumbers(string: String) -> Bool {
            return string.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
        }
        
        let card = cardFormView.cardTF.text!.filter { !$0.isWhitespace }
        
        if (card.count < 14 || !isStringContainsOnlyNumbers(string: card) || !luhnCheck(card)) {
            cardFormView.cardTF.textColor = .red
            return
        } else {
            cardFormView.cardTF.textColor = .black
        }
        
        let cvv = cardFormView.cvcTF.text!
        
        if (!isStringContainsOnlyNumbers(string: cvv) || cvv.count < 1) {
            cardFormView.cvcTF.textColor = .red
            return
        } else {
            cardFormView.cvcTF.textColor = .black
        }
        
        let exp = cardFormView.expTF.text?.split(separator: "/")
        
        let expMonth = String(exp![0])
        let expYear = "20" + exp![1]
        
        self.cardFormView.submitButton.showSpinner()
        
        let paymentInstrument = PaymentInstrument(number: card, cvv: cvv, expirationMonth: expMonth, expirationYear: expYear, cardholderName: name)
        let request = PaymentMethodTokenizationRequest(paymentInstrument: paymentInstrument, tokenType: TokenType.singleUse, paymentFlow: nil, customerId: nil)
        
        checkout.addPaymentMethod(
            request: request,
            onSuccess: {
                error in
                
                DispatchQueue.main.async {
                    
                    var alert: UIAlertController
                    
                    if error != nil {
                        alert = UIAlertController(title: "Error!", message: "Something went wrong. Please try again.", preferredStyle: UIAlertController.Style.alert)
                    } else {
                        
                        let message = self.checkout.uxMode == UXMode.ADD_PAYMENT_METHOD ? "Added new payment method." : "Payment completed."
                        
                        alert = UIAlertController(title: "Success!", message: message, preferredStyle: UIAlertController.Style.alert)
                        
                    }
                    
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: {
                        _ in
                        self.dismiss(animated: true, completion: {self.reloadDelegate?.reload()})
                    }))
                    
                    self.present(alert, animated: true, completion: nil)
                }
            })
        
    }
    
    @objc private func showScanner() {
        print("show scanner! 🤳")
        checkout.showScanner(self)
    }
    
    private func addSpinner() {
        spinner.color = .black
        view.addSubview(spinner)
        setSpinnerConstraints()
        spinner.startAnimating()
    }
    
    private func setSpinnerConstraints() {
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        spinner.widthAnchor.constraint(equalToConstant: 20).isActive = true
        spinner.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }
    
    private func removeSpinner() {
        self.spinner.removeFromSuperview()
    }
    
}

extension AddCardViewController: CreditCardDelegate {
    func setScannedCardDetails(_ details: CreditCardDetails) {
        self.cardFormView.nameTF.text = details.name
        self.cardFormView.cardTF.text = dateMask2.mask(input: details.number!, exhaustive: false)
        
        let expYr =  details.expiryYear!.count == 2 ? "20\(details.expiryYear!)" :  String(details.expiryYear!)
        
        self.cardFormView.expTF.text = String(format: "%02d", details.expiryMonth!) + "/" + expYr
    }
}
