//
//  VaultView.swift
//  DemoPrimerSDK
//
//  Created by Carl Eriksson on 05/12/2020.
//

import UIKit

class VaultView: UIView {
    
    private let cornerRadius: CGFloat = 8.0
    private let fieldHeight: CGFloat = 44.0
    
    let addressSection = UITableViewCell(style: .subtitle, reuseIdentifier: "addressCell")
    let paymentMethodSection = UITableViewCell()
    let payButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(addressSection)
        addSubview(paymentMethodSection)
        addSubview(payButton)
        
        configureAddressSection()
        configurePaymentMethodSection()
        configurePayButton()
        
        setAddressSectionContraints()
        setPaymentMethodSectionContraints()
        setPayButtonContraints()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // view configurations
    
    private func configureAddressSection() {
        
        addressSection.accessoryType = .disclosureIndicator
//        addressSection.accessoryView = UIView()
        
//        let textLabel = UILabel()
//        textLabel.text = "Monika Ocieczek"
//        textLabel.textColor = .black
//
//        let secondaryTextLabel = UILabel()
//        secondaryTextLabel.text = "Blekingegatan 42, 11662, Stockholm"
//
////        addressSection.textLabel?.text = "Monika Ocieczek"
//
//        addressSection.contentView.addSubview(textLabel)
//        addressSection.contentView.addSubview(secondaryTextLabel)
        
//        textLabel.translatesAutoresizingMaskIntoConstraints = false
//        textLabel.topAnchor.constraint(equalTo: addressSection.topAnchor, constant: 12).isActive = true
//        textLabel.leadingAnchor.constraint(equalTo: addressSection.leadingAnchor, constant: 0).isActive = true
//
//        secondaryTextLabel.translatesAutoresizingMaskIntoConstraints = false
//        secondaryTextLabel.topAnchor.constraint(equalTo: textLabel.bottomAnchor, constant: 8).isActive = true
//        secondaryTextLabel.leadingAnchor.constraint(equalTo: addressSection.leadingAnchor, constant: 0).isActive = true
        
        addressSection.textLabel?.text = "Monika Ocieczek"
        addressSection.detailTextLabel?.text = "Blekingegatan 42, 11662, Stockholm"
        
    }
    
    private func configurePaymentMethodSection() {
        paymentMethodSection.accessoryType = .disclosureIndicator
        paymentMethodSection.textLabel?.text = "**** **** **** 4402"
    }
    
    private func configurePayButton() {
        payButton.layer.cornerRadius = cornerRadius
        payButton.setTitle("Pay", for: .normal)
        payButton.setTitleColor(.white, for: .normal)
        payButton.backgroundColor = .black
    }
    
    // view constraints
    
    private func setAddressSectionContraints() {
        addressSection.translatesAutoresizingMaskIntoConstraints = false
        addressSection.topAnchor.constraint(equalTo: topAnchor, constant: 75).isActive = true
        addressSection.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        addressSection.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
        let heightAnchor = addressSection.heightAnchor.constraint(equalToConstant: 72.5)
        heightAnchor.priority = .defaultHigh
        heightAnchor.isActive = true
    }
    
    private func setPaymentMethodSectionContraints() {
        paymentMethodSection.translatesAutoresizingMaskIntoConstraints = false
        paymentMethodSection.topAnchor.constraint(equalTo: addressSection.contentView.bottomAnchor, constant: 12).isActive = true
        paymentMethodSection.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        paymentMethodSection.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
        let heightAnchor = paymentMethodSection.heightAnchor.constraint(equalToConstant: 72.5)
        heightAnchor.priority = .defaultHigh
        heightAnchor.isActive = true
    }
    
    private func setPayButtonContraints() {
        payButton.translatesAutoresizingMaskIntoConstraints = false
        payButton.topAnchor.constraint(equalTo: paymentMethodSection.contentView.bottomAnchor, constant: 12).isActive = true
        payButton.heightAnchor.constraint(equalToConstant: fieldHeight + 16).isActive = true
        payButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        payButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        payButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
    }
}
