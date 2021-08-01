//
//  PrimerUniversalCheckoutViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 31/7/21.
//

import UIKit

internal class PrimerUniversalCheckoutViewController: PrimerFormViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Enter your card details"
        
        view.backgroundColor = .white
        
        verticalStackView.spacing = 8
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        titleLabel.text = "Checkout"
        titleLabel.textAlignment = .center
        verticalStackView.addArrangedSubview(titleLabel)

        let cardNumberField = PrimerCardNumberFieldView()
        cardNumberField.translatesAutoresizingMaskIntoConstraints = false
        cardNumberField.placeholder = "4242 4242 4242 4242"
        cardNumberField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        cardNumberField.textColor = .black
        cardNumberField.borderStyle = .none
        cardNumberField.layoutIfNeeded()
        verticalStackView.addArrangedSubview(cardNumberField)
    }
    
}
