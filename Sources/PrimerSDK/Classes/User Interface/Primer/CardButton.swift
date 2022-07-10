//
//  CardButton.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 26/01/2021.
//

#if canImport(UIKit)

import UIKit

internal class CardButton: PrimerButton {

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
        guard let _model = model else { return }
        accessibilityIdentifier = "saved_payment_method_button"
        
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        backgroundColor = theme.paymentMethodButton.color(for: .enabled)

        addCheckmarkView()
        if showIcon {

        } else {
            toggleIcon()
        }

        addCardIcon(image: _model.imageName.image)
        addBorder()

        switch _model.paymentMethodType {
        case .goCardlessMandate,
             .klarnaCustomerToken:
            addDDMandateLabel(value: _model.network)
        default:
            addNetworkName(value: _model.network)
            addCardholderName(value: _model.cardholder)
            addLast4Digits(value: _model.last4)
            addExpiryDetails(value: _model.expiry)
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
        if (isError) {
            border.layer.borderColor = theme.colors.error.cgColor
            return
        }
        if (isSelected) {
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
        } else {
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
            iconView.heightAnchor.constraint(equalToConstant: 28).isActive = true
            iconView.widthAnchor.constraint(equalToConstant: 38).isActive = true
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
        checkmarkViewLeadingConstraint = last4Label.trailingAnchor
            .constraint(equalTo: checkView.leadingAnchor, constant: -14)
        checkmarkViewLeadingConstraint?.isActive = true
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

    private func addCheckmarkView() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        checkView = UIImageView(image: ImageName.check2.image)

        // color
        let tintedIcon = ImageName.check2.image?.withRenderingMode(.alwaysTemplate)
        checkView.tintColor = theme.paymentMethodButton.text.color
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
        line.backgroundColor = theme.paymentMethodButton.border.color(for: .disabled)
        line.translatesAutoresizingMaskIntoConstraints = false
        addSubview(line)
        line.topAnchor.constraint(equalTo: bottomAnchor, constant: -0.5).isActive = true
        line.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        line.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        line.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }
}

#endif
