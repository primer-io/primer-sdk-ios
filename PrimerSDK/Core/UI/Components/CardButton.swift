//
//  CardButton.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 26/01/2021.
//

import UIKit

class CardButton: UIButton {
    private var iconView = UIImageView()
    private var networkLabel = UILabel()
    private var cardholderLabel = UILabel()
    private var last4Label = UILabel()
    private var expiryLabel = UILabel()
    private var border = UIView()
    private var checkView = UIImageView()
    
    private weak var widthConstraint: NSLayoutConstraint?
    private weak var trailingConstraint: NSLayoutConstraint?
    
    func render(model: CardButtonViewModel?) {
        guard let model = model else { return }
        
        addCheckIcon()
        addCardIcon(image: model.imageName.image)
        addNetworkName(value: model.network)
        addCardholderName(value: model.cardholder)
        addLast4Digits(value: model.last4)
        addExpiryDetails(value: model.expiry)
        addBorder()
        
    }
    
    func reload(model: CardButtonViewModel?) {
        iconView.image = model?.imageName.image
        networkLabel.text = model?.network
        cardholderLabel.text = model?.cardholder
        last4Label.text = model?.last4
        expiryLabel.text = model?.expiry
        toggleBorder(isSelected: false)
        toggleIcon(isEnabled: true)
    }
    
    func toggleBorder(isSelected: Bool, isError: Bool = false) {
        if (isError) { return border.layer.borderColor = Primer.theme.colorTheme.error1.cgColor }
        border.layer.borderWidth = isSelected ? 1.5 : 1
        border.layer.borderColor = isSelected ? Primer.theme.colorTheme.tint1.cgColor : Primer.theme.colorTheme.disabled1.cgColor
    }
    
    private func addCardIcon(image: UIImage?) {
        iconView = UIImageView(image: image)
        addSubview(iconView)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        iconView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        iconView.heightAnchor.constraint(equalTo: heightAnchor, constant: -32).isActive = true
        iconView.widthAnchor.constraint(equalTo: iconView.heightAnchor, multiplier: 1.6).isActive = true
    }
    
    private func addNetworkName(value: String) {
        networkLabel = UILabel()
        networkLabel.text = value
        addSubview(networkLabel)
        networkLabel.translatesAutoresizingMaskIntoConstraints = false
        networkLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8).isActive = true
        networkLabel.bottomAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
    
    private func addCardholderName(value: String) {
        cardholderLabel = UILabel()
        cardholderLabel.text = value
        cardholderLabel.font = .systemFont(ofSize: 12)
        addSubview(cardholderLabel)
        cardholderLabel.translatesAutoresizingMaskIntoConstraints = false
        cardholderLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8).isActive = true
        cardholderLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -88).isActive = true
        cardholderLabel.topAnchor.constraint(equalTo: networkLabel.bottomAnchor, constant: 6).isActive = true
    }
    
    private func addLast4Digits(value: String) {
        last4Label = UILabel()
        last4Label.text = value
        addSubview(last4Label)
        last4Label.translatesAutoresizingMaskIntoConstraints = false
        last4Label.trailingAnchor.constraint(equalTo: checkView.leadingAnchor, constant: -10).isActive = true
        last4Label.bottomAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
    
    private func addExpiryDetails(value: String) {
        expiryLabel = UILabel()
        expiryLabel.text = value
        expiryLabel.font = .systemFont(ofSize: 12)
        addSubview(expiryLabel)
        expiryLabel.translatesAutoresizingMaskIntoConstraints = false
        expiryLabel.trailingAnchor.constraint(equalTo: checkView.leadingAnchor, constant: -10).isActive = true
        expiryLabel.topAnchor.constraint(equalTo: last4Label.bottomAnchor, constant: 6).isActive = true
    }
    
    private func addBorder() {
        border = UIView()
        border.layer.borderColor = Primer.theme.colorTheme.disabled1.cgColor
        border.layer.borderWidth = 1
        border.layer.cornerRadius = 4
        addSubview(border)
        border.translatesAutoresizingMaskIntoConstraints = false
        border.pin(to: self)
        border.isUserInteractionEnabled = false
    }
    
    private func addCheckIcon() {
        checkView = UIImageView(image: ImageName.check2.image)
        addSubview(checkView)
        checkView.translatesAutoresizingMaskIntoConstraints = false
        checkView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        trailingConstraint = checkView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
        trailingConstraint?.isActive = true
        widthConstraint = checkView.widthAnchor.constraint(equalToConstant: 20)
        widthConstraint?.isActive = true
        checkView.heightAnchor.constraint(equalTo: checkView.widthAnchor).isActive = true
        toggleIcon(isEnabled: widthConstraint?.constant != 0)
    }
    
    func toggleError(isEnabled: Bool) {
        checkView.image = isEnabled ? ImageName.delete.image : ImageName.check2.image
        toggleIcon(isEnabled: false)
        toggleBorder(isSelected: true, isError: isEnabled)
    }
    
    func toggleIcon(isEnabled: Bool) {
        trailingConstraint?.constant = isEnabled ? 0 : -10
        widthConstraint?.constant = isEnabled ? 0 : 12
    }
}
