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
    
    init(_ checkout: UniversalCheckoutProtocol) {
        self.checkout = checkout
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        view.addSubview(cardFormView)
        self.cardFormView.pin(to: self.view)
        self.cardFormView.cardTF.addTarget(self, action: #selector(textFieldDidChange2), for: .editingChanged)
        self.cardFormView.expTF.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        self.cardFormView.submitButton.addTarget(self, action: #selector(authorize), for: .touchUpInside)
        self.cardFormView.scannerButton.addTarget(self, action: #selector(showScanner), for: .touchUpInside)

        view.backgroundColor = bkgColor
        hideKeyboardWhenTappedAround()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    let dateMask = Veil(pattern: "##/##")
    
    @objc func textFieldDidChange(_ sender: UITextField) {
        guard let currentText = sender.text else  {
            return
        }

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
    
    @objc func authorize() {
        self.cardFormView.submitButton.isUserInteractionEnabled = false
        self.cardFormView.submitButton.setTitle("", for: .normal)
        let newSpinner = UIActivityIndicatorView()
        newSpinner.color = .white
        self.cardFormView.submitButton.addSubview(newSpinner)
        newSpinner.translatesAutoresizingMaskIntoConstraints = false
        newSpinner.centerXAnchor.constraint(equalTo: self.cardFormView.submitButton.centerXAnchor).isActive = true
        newSpinner.centerYAnchor.constraint(equalTo: self.cardFormView.submitButton.centerYAnchor).isActive = true
        newSpinner.widthAnchor.constraint(equalToConstant: 20).isActive = true
        newSpinner.heightAnchor.constraint(equalToConstant: 20).isActive = true
        newSpinner.startAnimating()
        
        checkout.addPaymentMethod ({
//            [weak self] result in
            
            DispatchQueue.main.async {
                
                var alert: UIAlertController
//                switch result {
//                case .failure(let err): alert = UIAlertController(title: "Error!", message: err.localizedDescription, preferredStyle: UIAlertController.Style.alert)
//                case .success: alert = UIAlertController(title: "Success!", message: "Added new payment method.", preferredStyle: UIAlertController.Style.alert)
//                }
                alert = UIAlertController(title: "Success!", message: "Added new payment method.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: {
                    _ in
                    self.dismiss(animated: true, completion: {
                        self.reloadDelegate?.reload()
                    })
                }))
                
                self.present(alert, animated: true, completion: nil)
            }
        })
        
    }
    
    @objc private func showScanner() {
        print("show scanner! 🤳")
        checkout.showScanner(self)
    }
    
}

extension AddCardViewController: CreditCardDelegate {
    func setScannedCardDetails(_ details: CreditCardDetails) {
        self.cardFormView.nameTF.text = details.name
        self.cardFormView.cardTF.text = details.number
        self.cardFormView.expTF.text = details.expiryMonth! + "/" + details.expiryYear!
    }
}
