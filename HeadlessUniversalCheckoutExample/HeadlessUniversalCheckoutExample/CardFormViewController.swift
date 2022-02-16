//
//  CardFormViewController.swift
//  HeadlessUniversalCheckoutExample
//
//  Created by Evangelos on 16/2/22.
//

import PrimerSDK
import UIKit

class CardFormViewController: UIViewController {
    
    static func instantiate() -> CardFormViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "CardFormViewController") as! CardFormViewController
    }

    @IBOutlet weak var stackView: UIStackView!
    var cardFormUIManager: PrimerHeadlessUniversalCheckout.CardFormUIManager!
    var cardNumberTextField: PrimerHeadlessUniversalCheckout.TextField!
    var expiryDateTextField: PrimerHeadlessUniversalCheckout.TextField!
    var cvvTextField: PrimerHeadlessUniversalCheckout.TextField!
    var cardholderNameTextField: PrimerHeadlessUniversalCheckout.TextField?
    var postalCodeTextField: PrimerHeadlessUniversalCheckout.TextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            self.cardFormUIManager = try PrimerHeadlessUniversalCheckout.CardFormUIManager()
            self.makeCardForm()
            
        } catch {
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                self.navigationController?.popViewController(animated: true)
            }))
        }
    }

    func makeCardForm() {
        stackView.backgroundColor = .blue
        
        for requiredInputElementType in self.cardFormUIManager.requiredInputElementTypes {
            let textField = PrimerHeadlessUniversalCheckout.TextField(type: requiredInputElementType, frame: .zero)
            textField.inputElementDelegate = self
            
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.heightAnchor.constraint(equalToConstant: 40).isActive = true
            textField.backgroundColor = .red
            
            textField.borderStyle = .line
            stackView.addArrangedSubview(textField)
            
        }
    }

}

extension CardFormViewController: PrimerInputElementDelegate {
    
}

extension CardFormViewController: PrimerCardFormDelegate {
    func cardFormUIManager(_ cardFormUIManager: PrimerHeadlessUniversalCheckout.CardFormUIManager, isCardFormValid: Bool) {
        
    }
}
