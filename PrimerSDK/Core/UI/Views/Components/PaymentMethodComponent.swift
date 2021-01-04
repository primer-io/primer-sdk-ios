//
//  PaymentMethodButton.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 03/01/2021.
//

import UIKit

class PaymentMethodComponent: UIView {
    
    let label: UILabel = UILabel()
    let iconView: UIImageView = UIImageView()
    
    init(frame: CGRect, method: PaymentMethodViewModel, theme: PrimerTheme) {
        super.init(frame: frame)
        layer.cornerRadius = theme.cornerRadiusTheme.buttons
        
        switch method.type {
        case .APPLE_PAY:
            backgroundColor = theme.buttonColorTheme.applePay
            label.textColor = .white
            addSubview(label)
            addSubview(iconView)
            configureLabel(with: method.toString(), isBold: true)
            configureIconView(with: method.toIconName().rawValue, color: .white)
            anchorLabel()
            anchorIconView(inRelationToLabel: true)
        case .PAYMENT_CARD:
            backgroundColor = theme.buttonColorTheme.creditCard
            label.textColor = theme.fontColorTheme.creditCard
            addSubview(label)
            addSubview(iconView)
            configureLabel(with: method.toString())
            configureIconView(with: method.toIconName().rawValue, color: theme.fontColorTheme.creditCard)
            anchorLabel()
            anchorIconView(inRelationToLabel: true)
        case .PAYPAL:
            backgroundColor = theme.buttonColorTheme.paypal
            addSubview(iconView)
            configureIconView(with: method.toIconName().rawValue, color: theme.fontColorTheme.paypal)
            anchorIconView(inRelationToLabel: false)
        default: break
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //
    
    func configureLabel(
        with title: String,
        isBold: Bool = false
    ) {
        label.text = title
        if (isBold) {
            label.font = UIFont.boldSystemFont(ofSize: 20)
        }
    }
    
    func configureIconView(with iconName: String, color: UIColor = .black) {
        let icon = UIImage(named: iconName)
        let tintedIcon = icon?.withRenderingMode(.alwaysTemplate)
        iconView.image = tintedIcon
        iconView.tintColor = color
    }
    
    //
    
    func anchorLabel() {
        label.translatesAutoresizingMaskIntoConstraints = false
        label.heightAnchor.constraint(equalToConstant: 20).isActive = true
        label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        label.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 12).isActive = true
    }
    
    func anchorIconView(inRelationToLabel: Bool) {
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        iconView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        if (inRelationToLabel) {
            iconView.trailingAnchor.constraint(equalTo: label.leadingAnchor, constant: -6).isActive = true
        } else {
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        }
    }
}
