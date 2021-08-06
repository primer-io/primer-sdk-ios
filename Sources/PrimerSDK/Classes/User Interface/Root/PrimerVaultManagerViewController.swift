//
//  PrimerVaultManagerViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 2/8/21.
//

import UIKit

internal class PrimerVaultManagerViewController: PrimerFormViewController {
    
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
        
        view.backgroundColor = .white
        
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
            otherPaymentMethodsTitleLabel.textColor = PrimerColor(rgb: 0x808080)
            otherPaymentMethodsTitleLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .regular)
            otherPaymentMethodsTitleLabel.textAlignment = .left
            verticalStackView.addArrangedSubview(otherPaymentMethodsTitleLabel)
            
            for paymentMethod in availablePaymentMethods {
                if paymentMethod.type == .applePay || paymentMethod.type == .googlePay {
                    continue
                }
                
                let paymentMethodButton = UIButton()
                paymentMethodButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
                paymentMethodButton.backgroundColor = .white
                paymentMethodButton.setTitle(paymentMethod.toString(), for: .normal)
                paymentMethodButton.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .medium)
                paymentMethodButton.setImage(paymentMethod.toIconName()?.image?.withRenderingMode(.alwaysTemplate), for: .normal)
                paymentMethodButton.imageEdgeInsets = UIEdgeInsets(top: -2, left: 0, bottom: 0, right: 10)
                paymentMethodButton.layer.cornerRadius = 4.0
                paymentMethodButton.clipsToBounds = true
                
                switch paymentMethod.type {
                case .paymentCard:
                    paymentMethodButton.setTitleColor(.black, for: .normal)
                    paymentMethodButton.tintColor = .black
                    paymentMethodButton.layer.borderWidth = 1.0
                    paymentMethodButton.layer.borderColor = UIColor.black.cgColor
                    paymentMethodButton.addTarget(self, action: #selector(cardButtonTapped), for: .touchUpInside)
                    verticalStackView.addArrangedSubview(paymentMethodButton)
                    
                case .payPal:
                    if #available(iOS 11.0, *) {
                        paymentMethodButton.backgroundColor = UIColor(red: 0.745, green: 0.894, blue: 0.996, alpha: 1)
                        paymentMethodButton.setTitleColor(.white, for: .normal)
                        paymentMethodButton.setImage(paymentMethod.toIconName()?.image, for: .normal)
                        paymentMethodButton.tintColor = .white
                        paymentMethodButton.addTarget(self, action: #selector(payPalButtonTapped), for: .touchUpInside)
                        verticalStackView.addArrangedSubview(paymentMethodButton)
                    }
                    
                case .goCardlessMandate:
                    paymentMethodButton.setTitleColor(.black, for: .normal)
                    paymentMethodButton.tintColor = .black
                    paymentMethodButton.layer.borderWidth = 1.0
                    paymentMethodButton.layer.borderColor = UIColor.black.cgColor
//                    verticalStackView.addArrangedSubview(paymentMethodButton)
                    
                case .klarna:
                    paymentMethodButton.backgroundColor = UIColor(red: 1, green: 0.702, blue: 0.78, alpha: 1)
                    paymentMethodButton.setTitleColor(.black, for: .normal)
                    paymentMethodButton.tintColor = .white
                    paymentMethodButton.setImage(nil, for: .normal)
                    paymentMethodButton.addTarget(self, action: #selector(klarnaButtonTapped), for: .touchUpInside)
                    verticalStackView.addArrangedSubview(paymentMethodButton)
                    
                default:
                    break
                }
            }
        }
        
    }
    
    @objc
    func klarnaButtonTapped() {
        let lvc = PrimerLoadingViewController(withHeight: 300)
        Primer.shared.primerRootVC?.show(viewController: lvc)
        Primer.shared.primerRootVC?.presentKlarna()
    }
    
    @objc
    func payPalButtonTapped() {
        if #available(iOS 11.0, *) {
            let lvc = PrimerLoadingViewController(withHeight: 300)
            Primer.shared.primerRootVC?.show(viewController: lvc)
            Primer.shared.primerRootVC?.presentPayPal()
        }
    }
    
    @objc
    func cardButtonTapped() {
        let cfvc = PrimerCardFormViewController(flow: .vault)
        Primer.shared.primerRootVC?.show(viewController: cfvc)
    }
    
}
