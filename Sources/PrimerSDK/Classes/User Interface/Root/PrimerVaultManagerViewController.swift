//
//  PrimerVaultManagerViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 2/8/21.
//

import UIKit

internal class PrimerVaultManagerViewController: PrimerFormViewController {
    
    let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    override var title: String? {
        didSet {
            (parent as? PrimerContainerViewController)?.title = title
        }
    }
    
    // swiftlint:disable function_body_length
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("primer-vault-nav-bar-title",
                                  tableName: nil,
                                  bundle: Bundle.primerResources,
                                  value: "Add payment method",
                                  comment: "Add payment method - Vault Navigation Bar Title")
        
        view.backgroundColor = theme.colorTheme.main1
        
        let checkoutViewModel: VaultCheckoutViewModelProtocol = DependencyContainer.resolve()
        let availablePaymentMethods = checkoutViewModel.availablePaymentOptions
        
        verticalStackView.spacing = 14.0
        
        if !availablePaymentMethods.isEmpty {
            let otherPaymentMethodsTitleLabel = UILabel()
            otherPaymentMethodsTitleLabel.text = NSLocalizedString("primer-vault-payment-method-available-payment-methods",
                                                                   tableName: nil,
                                                                   bundle: Bundle.primerResources,
                                                                   value: "Available payment methods",
                                                                   comment: "Available payment methods - Vault Checkout 'Available payment methods' Title").uppercased()
            
            otherPaymentMethodsTitleLabel.textColor = theme.colorTheme.secondaryText1
            otherPaymentMethodsTitleLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .regular)
            otherPaymentMethodsTitleLabel.textAlignment = .left
            verticalStackView.addArrangedSubview(otherPaymentMethodsTitleLabel)
            
            for paymentMethod in availablePaymentMethods {
                let paymentMethodButton = UIButton()
                paymentMethodButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
                paymentMethodButton.backgroundColor = paymentMethod.buttonColor
                paymentMethodButton.setTitle(paymentMethod.buttonTitle, for: .normal)
                paymentMethodButton.setTitleColor(paymentMethod.buttonTitleColor, for: .normal)
                paymentMethodButton.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .medium)
                paymentMethodButton.setImage(paymentMethod.buttonImage, for: .normal)
                paymentMethodButton.tintColor = paymentMethod.buttonTintColor
                paymentMethodButton.imageEdgeInsets = UIEdgeInsets(top: -2, left: 0, bottom: 0, right: 10)
                if let buttonCornerRadius = paymentMethod.buttonCornerRadius {
                    paymentMethodButton.layer.cornerRadius = buttonCornerRadius
                }
                paymentMethodButton.layer.borderWidth = paymentMethod.buttonBorderWidth
                paymentMethodButton.layer.borderColor = paymentMethod.buttonBorderColor?.cgColor
                paymentMethodButton.clipsToBounds = true
                
                switch paymentMethod.config.type {
                case .apaya:
                    paymentMethodButton.addTarget(self, action: #selector(apayaButtonTapped(_:)), for: .touchUpInside)
                    verticalStackView.addArrangedSubview(paymentMethodButton)
                    
                case .paymentCard:
                    paymentMethodButton.addTarget(self, action: #selector(cardButtonTapped), for: .touchUpInside)
                    verticalStackView.addArrangedSubview(paymentMethodButton)
                    
                case .payPal:
                    if #available(iOS 11.0, *) {
                        paymentMethodButton.addTarget(self, action: #selector(payPalButtonTapped), for: .touchUpInside)
                        verticalStackView.addArrangedSubview(paymentMethodButton)
                    }
                    
                case .klarna:
                    paymentMethodButton.addTarget(self, action: #selector(klarnaButtonTapped), for: .touchUpInside)
                    verticalStackView.addArrangedSubview(paymentMethodButton)
                    
                case .applePay,
                        .hoolah,
                        .goCardlessMandate,
                        .googlePay,
                        .payNLIdeal,
                        .unknown:
                    break
                    
                }
            }
        }
        
    }
    
    @objc
    func apayaButtonTapped(_ sender: UIButton) {
        Primer.shared.primerRootVC?.showLoadingScreenIfNeeded()
        Primer.shared.primerRootVC?.presentApaya()
    }
    
    @objc
    func klarnaButtonTapped() {
        Primer.shared.primerRootVC?.showLoadingScreenIfNeeded()
        Primer.shared.primerRootVC?.presentKlarna()
    }
    
    @objc
    func payPalButtonTapped() {
        if #available(iOS 11.0, *) {
            Primer.shared.primerRootVC?.showLoadingScreenIfNeeded()
            Primer.shared.primerRootVC?.presentPayPal()
        }
    }
    
    @objc
    func cardButtonTapped() {
        let cfvc = PrimerCardFormViewController(flow: .vault)
        Primer.shared.primerRootVC?.show(viewController: cfvc)
    }
    
}
