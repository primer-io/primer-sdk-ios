//
//  CardButton.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 26/01/2021.
//

import UIKit

class CardButton: UIButton {
    
    @Dependency private(set) var theme: PrimerThemeProtocol
    
    private var iconView = UIImageView()
    private var networkLabel = UILabel()
    private var cardholderLabel = UILabel()
    private var last4Label = UILabel()
    private var expiryLabel = UILabel()
    private var border = UIView()
    private var checkView = UIImageView()
    
    private weak var widthConstraint: NSLayoutConstraint?
    private weak var trailingConstraint: NSLayoutConstraint?
    private weak var leadingConstraint: NSLayoutConstraint?
    private weak var heightConstraint: NSLayoutConstraint?
    
    var showIcon = true
    
    func render(model: CardButtonViewModel?, showIcon: Bool = true) {
        guard let model = model else { return }

        addIcon()
        if (showIcon) {
            
        } else {
            self.showIcon = false
            toggleIcon()
        }
        
        addCardIcon(image: model.imageName.image)
        addBorder()
        
        if (model.paymentMethodType == .GOCARDLESS_MANDATE) {
            addDDMandateLabel(value: model.network)
        } else {
            addNetworkName(value: model.network)
            addCardholderName(value: model.cardholder)
            addLast4Digits(value: model.last4)
            addExpiryDetails(value: model.expiry)
        }
        
    }
    
    func reload(model: CardButtonViewModel?) {
        iconView.image = model?.imageName.image
        networkLabel.text = model?.network
        cardholderLabel.text = model?.cardholder
        last4Label.text = model?.last4
        expiryLabel.text = model?.expiry
        toggleBorder(isSelected: false)
    }
    
    func toggleBorder(isSelected: Bool, isError: Bool = false) {
        if (isError) { return border.layer.borderColor = theme.colorTheme.error1.cgColor }
        border.layer.borderWidth = isSelected ? 1.5 : 1
        border.layer.borderColor = isSelected ? theme.colorTheme.tint1.cgColor : theme.colorTheme.disabled1.cgColor
    }
    
    private func addCardIcon(image: UIImage?) {
        iconView = UIImageView(image: image)
        iconView.clipsToBounds = true
        addSubview(iconView)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        if (iconView.image == ImageName.bank.image) {
            
            let tintedIcon = image?.withRenderingMode(.alwaysTemplate)
            iconView.tintColor = theme.colorTheme.tint1
            iconView.image = tintedIcon
            
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 17).isActive = true
            iconView.heightAnchor.constraint(equalToConstant: 24).isActive = true
            iconView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        } else {
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
            iconView.heightAnchor.constraint(equalToConstant: 28).isActive = true
            iconView.widthAnchor.constraint(equalToConstant: 38).isActive = true
        }
    }
    
    private func addDDMandateLabel(value: String) {
        let label = UILabel()
        label.text = value
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 17).isActive = true
        label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
    
    private func addNetworkName(value: String) {
        networkLabel = UILabel()
        networkLabel.text = value
        addSubview(networkLabel)
        networkLabel.translatesAutoresizingMaskIntoConstraints = false
        if (iconView.image == ImageName.bank.image?.withRenderingMode(.alwaysTemplate)) {
            networkLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 17).isActive = true
        } else {
            networkLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10).isActive = true
        }
        networkLabel.bottomAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
    
    private func addCardholderName(value: String) {
        cardholderLabel = UILabel()
        cardholderLabel.text = value
        cardholderLabel.font = .systemFont(ofSize: 12)
        addSubview(cardholderLabel)
        cardholderLabel.translatesAutoresizingMaskIntoConstraints = false
        cardholderLabel.leadingAnchor.constraint(equalTo: networkLabel.leadingAnchor).isActive = true
        cardholderLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -88).isActive = true
        cardholderLabel.topAnchor.constraint(equalTo: networkLabel.bottomAnchor, constant: 6).isActive = true
    }
    
    private func addLast4Digits(value: String) {
        last4Label = UILabel()
        last4Label.text = value
        addSubview(last4Label)
        last4Label.translatesAutoresizingMaskIntoConstraints = false
        leadingConstraint = last4Label.trailingAnchor.constraint(equalTo: checkView.leadingAnchor, constant: -14)
        leadingConstraint?.isActive = true
        last4Label.bottomAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
    
    private func addExpiryDetails(value: String) {
        expiryLabel = UILabel()
        expiryLabel.text = value
        expiryLabel.font = .systemFont(ofSize: 12)
        addSubview(expiryLabel)
        expiryLabel.translatesAutoresizingMaskIntoConstraints = false
        expiryLabel.trailingAnchor.constraint(equalTo: last4Label.trailingAnchor).isActive = true
        expiryLabel.topAnchor.constraint(equalTo: last4Label.bottomAnchor, constant: 6).isActive = true
    }
    
    private func addBorder() {
        border = UIView()
        border.layer.borderColor = theme.colorTheme.disabled1.cgColor
        border.layer.borderWidth = 1
        border.layer.cornerRadius = 4
        addSubview(border)
        border.translatesAutoresizingMaskIntoConstraints = false
        border.pin(to: self)
        border.isUserInteractionEnabled = false
    }
    
    private func addIcon() {
        checkView = UIImageView(image: ImageName.check2.image)
        
        // color
        let tintedIcon = ImageName.check2.image?.withRenderingMode(.alwaysTemplate)
        checkView.tintColor = theme.colorTheme.tint1
        checkView.image = tintedIcon
        
        addSubview(checkView)
        checkView.translatesAutoresizingMaskIntoConstraints = false
        checkView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        trailingConstraint = checkView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14)
        widthConstraint = checkView.widthAnchor.constraint(equalToConstant: 14)
        trailingConstraint?.isActive = true
        widthConstraint?.isActive = true
        heightConstraint = checkView.heightAnchor.constraint(equalToConstant: 22)
        heightConstraint?.isActive = true
    }
    
    func toggleError(isEnabled: Bool) {
        checkView.image = isEnabled ? ImageName.delete.image : ImageName.check2.image
        
        if (checkView.image == ImageName.check2.image) {
            leadingConstraint?.constant = -14
            trailingConstraint?.constant = 14
            widthConstraint?.constant = 14
            heightConstraint?.constant = 14
        } else {
            leadingConstraint?.constant = -10
            trailingConstraint?.constant = -10
            widthConstraint?.constant = 22
        }
    }
    
    func toggleIcon() {
        trailingConstraint?.constant = showIcon ? -14 : 0
        widthConstraint?.constant = showIcon ? 14 : 0
        heightConstraint?.constant = showIcon ? 14 : 0
    }
    
    func hideIcon(_ val: Bool) {
        checkView.isHidden = !val
    }
    
    func hideBorder() {
        border.isHidden = true
    }
    
    func addSeparatorLine() {
        let line = UIView()
        line.backgroundColor = theme.colorTheme.disabled1
        line.translatesAutoresizingMaskIntoConstraints = false
        addSubview(line)
        line.topAnchor.constraint(equalTo: bottomAnchor, constant: -0.5).isActive = true
        line.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        line.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        line.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }
}
