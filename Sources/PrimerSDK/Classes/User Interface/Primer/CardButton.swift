//
//  CardButton.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 26/01/2021.
//

#if canImport(UIKit)

import UIKit

internal class CardButton: PrimerOldButton {

    private var iconView = UIImageView()
    private var networkLabel = UILabel()
    private var cardholderLabel = UILabel()
    private var last4Label = UILabel()
    private var expiryLabel = UILabel()
    private var border = PrimerView()
    private var checkView = UIImageView()

    private weak var checkmarkViewWidthConstraint: NSLayoutConstraint?
    private weak var checkmarkViewTrailingConstraint: NSLayoutConstraint?
    private weak var checkmarkViewLeadingConstraint: NSLayoutConstraint?
    private weak var checkmarkViewHeightConstraint: NSLayoutConstraint?

    var showIcon = true

    func render(model: CardButtonViewModel?, showIcon: Bool = true) {
        guard let model = model else { return }
        accessibilityIdentifier = "saved_payment_method_button"

        addCheckmarkView()
        if showIcon {

        } else {
            toggleIcon()
        }

        addCardIcon(image: model.imageName.image)
        addBorder()

        switch model.paymentMethodType {
        case .goCardlessMandate,
             .klarnaCustomerToken:
            addDDMandateLabel(value: model.network)
        default:
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
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        if isError { return border.layer.borderColor = theme.colorTheme.error1.cgColor }
        border.layer.borderWidth = isSelected ? 1.5 : 1
        border.layer.borderColor = isSelected ? theme.colorTheme.tint1.cgColor : theme.colorTheme.disabled1.cgColor
    }

    private func addCardIcon(image: UIImage?) {
        iconView = UIImageView(image: image)
        iconView.clipsToBounds = true
        iconView.contentMode = .scaleAspectFit
        
        addSubview(iconView)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        if iconView.image == ImageName.bank.image {
            let theme: PrimerThemeProtocol = DependencyContainer.resolve()
            
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
        if iconView.image == ImageName.bank.image?.withRenderingMode(.alwaysTemplate) {
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
        checkmarkViewLeadingConstraint = last4Label.trailingAnchor.constraint(equalTo: checkView.leadingAnchor, constant: -14)
        checkmarkViewLeadingConstraint?.isActive = true
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
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        border = PrimerView()
        border.layer.borderColor = theme.colorTheme.disabled1.cgColor
        border.layer.borderWidth = 1
        border.layer.cornerRadius = 4
        addSubview(border)
        border.translatesAutoresizingMaskIntoConstraints = false
        border.pin(to: self)
        border.isUserInteractionEnabled = false
    }

    private func addCheckmarkView() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        checkView = UIImageView(image: ImageName.check2.image)

        // color
        let tintedIcon = ImageName.check2.image?.withRenderingMode(.alwaysTemplate)
        checkView.tintColor = theme.colorTheme.tint1
        checkView.image = tintedIcon

        addSubview(checkView)
        checkView.translatesAutoresizingMaskIntoConstraints = false
        checkView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        checkmarkViewTrailingConstraint = checkView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14)
        checkmarkViewWidthConstraint = checkView.widthAnchor.constraint(equalToConstant: 14)
        checkmarkViewTrailingConstraint?.isActive = true
        checkmarkViewWidthConstraint?.isActive = true
        checkmarkViewHeightConstraint = checkView.heightAnchor.constraint(equalToConstant: 22)
        checkmarkViewHeightConstraint?.isActive = true
    }

    func showDeleteIcon(_ flag: Bool) {
        checkView.image = flag ? ImageName.delete.image : ImageName.check2.image
    }

    func toggleIcon() {
        checkmarkViewTrailingConstraint?.constant = showIcon ? -14 : 0
        checkmarkViewWidthConstraint?.constant = showIcon ? 14 : 0
        checkmarkViewHeightConstraint?.constant = showIcon ? 14 : 0
    }

    func showCheckmarkIcon(_ val: Bool) {
        checkView.isHidden = !val
    }

    func hideBorder() {
        border.isHidden = true
    }

    func addSeparatorLine() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
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

#endif
