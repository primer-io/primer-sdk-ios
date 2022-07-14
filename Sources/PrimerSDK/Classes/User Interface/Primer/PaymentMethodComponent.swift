//
//  PaymentMethodButton.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 03/01/2021.
//

#if canImport(UIKit)

import UIKit

internal class PaymentMethodComponent: PrimerView {

    let label = UILabel()
    let iconView = UIImageView()

    init(frame: CGRect, method: ExternalPaymentMethodTokenizationViewModel) {
        super.init(frame: frame)
        
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()

        layer.cornerRadius = theme.paymentMethodButton.cornerRadius

        switch method.config.type {
        case .applePay:
            backgroundColor = .black
            label.textColor = .white
            addSubview(label)
            addSubview(iconView)
            configureLabel(with: method.uiModule.buttonTitle, isBold: true)
            configureIconView(icon: method.uiModule.buttonImage, color: .white, isMonoColor: true)
            anchorLabel()
            anchorIconView(inRelationToLabel: true)
        case .paymentCard:
            layer.borderWidth = 1
            layer.borderColor = theme.paymentMethodButton.border.color(for: .enabled).cgColor
            backgroundColor = theme.paymentMethodButton.color(for: .enabled)
            label.textColor = theme.paymentMethodButton.text.color
            addSubview(label)
            addSubview(iconView)
            configureLabel(with: method.uiModule.buttonTitle)
            configureIconView(icon: method.uiModule.buttonImage, color: theme.paymentMethodButton.text.color, isMonoColor: true)
            anchorLabel()
            anchorIconView(inRelationToLabel: true)
        case .payPal:
//            layer.borderWidth = 1
            backgroundColor = UIColor(red: 190/255, green: 228/255, blue: 254/255, alpha: 1)
            //            layer.borderColor = theme.colorTheme.disabled1.cgColor
            addSubview(iconView)
            configureIconView(icon: method.uiModule.buttonImage, color: theme.paymentMethodButton.text.color)
            anchorIconView(inRelationToLabel: false)
        case .goCardlessMandate:
            layer.borderWidth = 1
            layer.borderColor = theme.paymentMethodButton.border.color(for: .enabled).cgColor
            backgroundColor = theme.paymentMethodButton.color(for: .enabled)
            label.textColor = theme.paymentMethodButton.text.color
            addSubview(label)
            addSubview(iconView)
            configureLabel(with: method.uiModule.buttonTitle)
            configureIconView(icon: method.uiModule.buttonImage, color: theme.paymentMethodButton.text.color, isMonoColor: true)
            anchorLabel()
            anchorIconView(inRelationToLabel: true)
        case .klarna:
            // TODO: move Klarna color to constant or similar, should maybe be dynamic from backend?
            backgroundColor = UIColor(red: 255/255, green: 179/255, blue: 199/255, alpha: 1)
            addSubview(iconView)
            configureIconView(icon: method.uiModule.buttonImage, color: theme.paymentMethodButton.text.color)
            anchorIconView(inRelationToLabel: false)
        case .apaya:
            layer.borderWidth = 1
            layer.borderColor = theme.paymentMethodButton.border.color(for: .enabled).cgColor
            backgroundColor = theme.paymentMethodButton.color(for: .enabled)
            label.textColor = theme.paymentMethodButton.text.color
            addSubview(label)
            addSubview(iconView)
            configureLabel(with: method.uiModule.buttonTitle)
            configureIconView(icon: method.uiModule.buttonImage, color: theme.paymentMethodButton.text.color, isMonoColor: true)
            anchorLabel()
            anchorIconView(inRelationToLabel: true)
        default:
            break
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: Configuration
internal extension PaymentMethodComponent {
    func configureLabel(
        with title: String?,
        isBold: Bool = false
    ) {
        label.text = title
        if isBold {
            label.font = UIFont.boldSystemFont(ofSize: 20)
        }
    }

    func configureIconView(icon: UIImage?, color: UIColor = .black, isMonoColor: Bool = false) {
        if isMonoColor {
            let tintedIcon = icon?.withRenderingMode(.alwaysTemplate)
            iconView.tintColor = color
            iconView.image = tintedIcon
        } else {
            iconView.image = icon
        }
    }
}

// MARK: Constraints
internal extension PaymentMethodComponent {
    func anchorLabel() {
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        label.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 12).isActive = true
    }

    func anchorIconView(inRelationToLabel: Bool) {
        iconView.translatesAutoresizingMaskIntoConstraints = false
//        iconView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        iconView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: iconView.intrinsicContentSize.height * 0.75)
            .isActive = true
        iconView.widthAnchor.constraint(equalToConstant: iconView.intrinsicContentSize.width * 0.75)
            .isActive = true
        if inRelationToLabel {
            iconView.trailingAnchor.constraint(equalTo: label.leadingAnchor, constant: -6).isActive = true
        } else {
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        }
    }
}

#endif
