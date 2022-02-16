//
//  CardFormViewController.swift
//  HeadlessUniversalCheckoutExample
//
//  Created by Evangelos on 16/2/22.
//

import PrimerSDK
import UIKit

class CardFormViewController: MyViewController {
    
    static func instantiate() -> CardFormViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "CardFormViewController") as! CardFormViewController
    }

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var payButton: UIButton!
    var cardFormUIManager: PrimerHeadlessUniversalCheckout.CardFormUIManager!
    var cardNumberTextField: PrimerInputTextField!
    var expiryDateTextField: PrimerInputTextField!
    var cvvTextField: PrimerInputTextField!
    var cardholderNameTextField: PrimerInputTextField?
    var postalCodeTextField: PrimerInputTextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.stackView.backgroundColor = .clear
        self.stackView.spacing = 6
        self.payButton.isEnabled = false
        self.payButton.setTitleColor(.gray, for: .disabled)
        
        do {
            PrimerHeadlessUniversalCheckout.current.delegate = self
            self.cardFormUIManager = try PrimerHeadlessUniversalCheckout.CardFormUIManager()
            self.cardFormUIManager.cardFormUIManagerDelegate = self
            self.makeCardForm()
            
        } catch {
            self.stopLoading()
            self.showError(withMessage: error.localizedDescription)
        }
    }

    func makeCardForm() {
        var inputElements: [PrimerInputTextField] = []
        
        for requiredInputElementType in self.cardFormUIManager.requiredInputElementTypes {
            let textField = PrimerInputTextField(type: requiredInputElementType, frame: .zero)
            textField.inputElementDelegate = self
            
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.heightAnchor.constraint(equalToConstant: 40).isActive = true
            textField.backgroundColor = .white
            textField.borderStyle = .none
            textField.layer.cornerRadius = 4.0
            textField.layer.borderWidth = 1.0
            textField.layer.borderColor = UIColor.systemBlue.cgColor
            textField.layer.sublayerTransform = CATransform3DMakeTranslation(5, 0, 0);
        
            switch requiredInputElementType {
            case .cardNumber:
                textField.placeholder = "4242 4242 4242 4242"
            case .expiryDate:
                textField.placeholder = "02/24"
            case .cvv:
                textField.placeholder = "123"
            case .cardholderName:
                textField.placeholder = "John Smith"
            default:
                break
            }
            
            inputElements.append(textField)
        }
        
        if let cardNumberField = inputElements.filter({ $0.type == .cardNumber }).first {
            self.stackView.addArrangedSubview(cardNumberField)
        }
        
        if let expiryDateField = inputElements.filter({ $0.type == .expiryDate }).first,
           let cvvField = inputElements.filter({ $0.type == .cvv }).first {
            let rowStackView = UIStackView()
            rowStackView.axis = .horizontal
            rowStackView.spacing = 6.0
            rowStackView.distribution = .fillEqually
            rowStackView.addArrangedSubview(expiryDateField)
            rowStackView.addArrangedSubview(cvvField)
            
            self.stackView.addArrangedSubview(rowStackView)
            rowStackView.translatesAutoresizingMaskIntoConstraints = false
        }
        
        if let cardholderNameField = inputElements.filter({ $0.type == .cardholderName }).first {
            self.stackView.addArrangedSubview(cardholderNameField)
        }
        
        if let postalCodeField = inputElements.filter({ $0.type == .postalCode }).first {
            self.stackView.addArrangedSubview(postalCodeField)
        }
    }

    @IBAction func payButtonTapped(_ sender: Any) {
        self.cardFormUIManager.startTokenization()
    }
    
}

extension CardFormViewController: PrimerInputElementDelegate {
    func inputElementDidBlur(_ sender: PrimerInputElement) {
        
    }
    
    func inputElementDidFocus(_ sender: PrimerInputElement) {
        
    }
    
    func inputElementValueDidChange(_ sender: PrimerInputElement) {
        
    }
    
    func inputElementDidDetectType(_ sender: PrimerInputElement, type: Any?) {
        
    }
    
    func inputElementValueIsValid(_ sender: PrimerInputElement, isValid: Bool) {
        
    }
}

extension CardFormViewController: PrimerCardFormDelegate {
    func cardFormUIManager(_ cardFormUIManager: PrimerHeadlessUniversalCheckout.CardFormUIManager, isCardFormValid: Bool) {
        self.payButton.isEnabled = isCardFormValid
    }
}

extension CardFormViewController: PrimerHeadlessUniversalCheckoutDelegate {
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
