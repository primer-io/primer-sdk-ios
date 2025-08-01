//
//  CardButton.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

final class CardButton: PrimerButton {

    private var iconView = UIImageView()
    private var networkLabel = UILabel()
    private var cardholderLabel = UILabel()
    private var last4Label = UILabel()
    private var expiryLabel = UILabel()
    private var border = PrimerView()

    func render(model: CardButtonViewModel?) {
        guard let model = model else { return }
        accessibilityIdentifier = "saved_payment_method_button"

        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        backgroundColor = theme.paymentMethodButton.color(for: .enabled)

        if model.paymentMethodType == .paymentCard || model.paymentMethodType == .cardOffSession {
            addCardIcon(image: CardNetwork(cardNetworkStr: model.network).icon)
        } else {
            addCardIcon(image: model.imageName.image)
        }

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
        if isError {
            border.layer.borderColor = theme.colors.error.cgColor
            return
        }
        if isSelected {
            border.layer.borderWidth = theme.paymentMethodButton.border.width
            border.layer.borderColor = theme.paymentMethodButton.color(for: .selected).cgColor
        } else {
            border.layer.borderWidth = theme.paymentMethodButton.border.width
            border.layer.borderColor = theme.paymentMethodButton.border.color(for: .enabled).cgColor
        }
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
            iconView.tintColor = theme.paymentMethodButton.iconColor
            iconView.image = tintedIcon
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 17).isActive = true
            iconView.heightAnchor.constraint(equalToConstant: 24).isActive = true
            iconView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        } else if iconView.image == ImageName.achBank.image {
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
            iconView.widthAnchor.constraint(equalToConstant: 56).isActive = true
        } else {
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
            iconView.heightAnchor.constraint(equalToConstant: 41).isActive = true
            iconView.widthAnchor.constraint(equalToConstant: 56).isActive = true
        }
    }

    private func addDDMandateLabel(value: String) {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        let label = UILabel()
        label.text = value
        label.textColor = theme.paymentMethodButton.text.color
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 17)
            .isActive = true
        label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }

    private func addNetworkName(value: String) {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        networkLabel = UILabel()
        networkLabel.text = value
        networkLabel.textColor = theme.paymentMethodButton.text.color
        addSubview(networkLabel)
        networkLabel.translatesAutoresizingMaskIntoConstraints = false
        if iconView.image == ImageName.bank.image?.withRenderingMode(.alwaysTemplate) {
            networkLabel.leadingAnchor.constraint(
                equalTo: iconView.trailingAnchor,
                constant: 17
            ).isActive = true
        } else {
            networkLabel.leadingAnchor.constraint(
                equalTo: iconView.trailingAnchor,
                constant: 10
            ).isActive = true
        }
        networkLabel.bottomAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }

    private func addCardholderName(value: String) {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        cardholderLabel = UILabel()
        cardholderLabel.text = value
        cardholderLabel.textColor = theme.paymentMethodButton.text.color
        cardholderLabel.font = .systemFont(ofSize: 12)
        addSubview(cardholderLabel)
        cardholderLabel.translatesAutoresizingMaskIntoConstraints = false
        cardholderLabel.leadingAnchor.constraint(equalTo: networkLabel.leadingAnchor).isActive = true
        cardholderLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -88).isActive = true
        cardholderLabel.topAnchor.constraint(equalTo: networkLabel.bottomAnchor, constant: 6).isActive = true
    }

    private func addLast4Digits(value: String) {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        last4Label = UILabel()
        last4Label.text = value
        last4Label.textColor = theme.paymentMethodButton.text.color
        addSubview(last4Label)
        last4Label.translatesAutoresizingMaskIntoConstraints = false
        last4Label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14).isActive = true
        last4Label.bottomAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }

    private func addExpiryDetails(value: String) {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        expiryLabel = UILabel()
        expiryLabel.text = value
        expiryLabel.textColor = theme.paymentMethodButton.text.color
        expiryLabel.font = .systemFont(ofSize: 12)
        addSubview(expiryLabel)
        expiryLabel.translatesAutoresizingMaskIntoConstraints = false
        expiryLabel.trailingAnchor.constraint(equalTo: last4Label.trailingAnchor).isActive = true
        expiryLabel.topAnchor.constraint(equalTo: last4Label.bottomAnchor, constant: 6).isActive = true
    }

    private func addBorder() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()

        border = PrimerView()
        border.layer.borderColor = theme.paymentMethodButton.border.color(for: .enabled).cgColor
        border.layer.borderWidth = theme.paymentMethodButton.border.width
        border.layer.cornerRadius = theme.paymentMethodButton.cornerRadius
        addSubview(border)
        border.translatesAutoresizingMaskIntoConstraints = false
        border.pin(to: self)
        border.isUserInteractionEnabled = false
    }

    func hideBorder() {
        border.isHidden = true
    }

    func addSeparatorLine() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()

        let line = UIView()
        line.backgroundColor = theme.paymentMethodButton.border.color(for: .disabled)
        line.translatesAutoresizingMaskIntoConstraints = false
        addSubview(line)
        line.topAnchor.constraint(equalTo: bottomAnchor, constant: -0.5).isActive = true
        line.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        line.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        line.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }
}
