//
//  PrimerUniversalCheckoutViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 31/7/21.
//

import UIKit

internal class PrimerUniversalCheckoutViewController: PrimerFormViewController {
    
    // swiftlint:disable function_body_length
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("primer-checkout-nav-bar-title",
                                          tableName: nil,
                                          bundle: Bundle.primerResources,
                                          value: "Choose payment method",
                                          comment: "Choose payment method - Checkout Navigation Bar Title")
        
        view.backgroundColor = .white
        
        let checkoutViewModel: VaultCheckoutViewModelProtocol = DependencyContainer.resolve()
        let availablePaymentMethods = checkoutViewModel.availablePaymentOptions
        
        verticalStackView.spacing = 14.0
        
        if let amountStr = checkoutViewModel.amountStringed {
            let titleLabel = UILabel()
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true
            titleLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
            titleLabel.text = amountStr
            titleLabel.textAlignment = .left
            verticalStackView.addArrangedSubview(titleLabel)
        }
        
        if let selectedPaymentInstrument = checkoutViewModel.paymentMethods.first(where: { paymentInstrument in
            return paymentInstrument.token == checkoutViewModel.selectedPaymentMethodId
        }), let cardButtonViewModel =  selectedPaymentInstrument.cardButtonViewModel {
            let savedPaymentInstrumentTitleLabel = UILabel()
            savedPaymentInstrumentTitleLabel.text = NSLocalizedString("primer-vault-checkout-payment-method-title",
                                                                      tableName: nil,
                                                                      bundle: Bundle.primerResources,
                                                                      value: "SAVED PAYMENT METHOD",
                                                                      comment: "SAVED PAYMENT METHOD - Vault Checkout Card Title")
            savedPaymentInstrumentTitleLabel.textColor = PrimerColor(rgb: 0x808080)
            savedPaymentInstrumentTitleLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .regular)
            savedPaymentInstrumentTitleLabel.textAlignment = .left
            verticalStackView.addArrangedSubview(savedPaymentInstrumentTitleLabel)
            
            let savedCardButtonView = CardButton()
            savedCardButtonView.translatesAutoresizingMaskIntoConstraints = false
            savedCardButtonView.heightAnchor.constraint(equalToConstant: 64.0).isActive = true
            savedCardButtonView.render(model: cardButtonViewModel, showIcon: false)
            verticalStackView.addArrangedSubview(savedCardButtonView)
            
            let seeAllButton = UIButton()
            seeAllButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
            seeAllButton.setTitle("See all", for: .normal)
            seeAllButton.setTitleColor(PrimerColor(rgb: 0x007AFF), for: .normal)
            seeAllButton.addTarget(self, action: #selector(seeAllButtonTapped), for: .touchUpInside)
            verticalStackView.addArrangedSubview(seeAllButton)
        }
        
        if !availablePaymentMethods.filter({ $0.type != .googlePay }).isEmpty {
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
                    
                case .applePay:
                    paymentMethodButton.backgroundColor = .black
                    paymentMethodButton.setTitleColor(.white, for: .normal)
                    paymentMethodButton.tintColor = .white
                    paymentMethodButton.addTarget(self, action: #selector(applePayButtonTapped(_:)), for: .touchUpInside)
                    
                case .payPal:
                    if #available(iOS 11.0, *) {
                        paymentMethodButton.backgroundColor = UIColor(red: 0.745, green: 0.894, blue: 0.996, alpha: 1)
                        paymentMethodButton.setImage(paymentMethod.toIconName()?.image, for: .normal)
                        paymentMethodButton.setTitleColor(.white, for: .normal)
                        paymentMethodButton.tintColor = .white
                        paymentMethodButton.addTarget(self, action: #selector(payPalButtonTapped), for: .touchUpInside)
                    }
                    
                case .goCardlessMandate:
                    paymentMethodButton.setTitleColor(.white, for: .normal)
                    paymentMethodButton.tintColor = .white
                    paymentMethodButton.layer.borderWidth = 1.0
                    paymentMethodButton.layer.borderColor = UIColor.black.cgColor
                    
                case .klarna:
                    paymentMethodButton.backgroundColor = UIColor(red: 1, green: 0.702, blue: 0.78, alpha: 1)
                    paymentMethodButton.setTitleColor(.black, for: .normal)
                    paymentMethodButton.tintColor = .white
                    paymentMethodButton.setImage(nil, for: .normal)
                    paymentMethodButton.addTarget(self, action: #selector(klarnaButtonTapped), for: .touchUpInside)
                    
                default:
                    break
                }
                
                verticalStackView.addArrangedSubview(paymentMethodButton)
            }
        }
        
        var backButton = UIButton(frame: CGRect(x: 0, y: 0, width: 22, height: 22))
        backButton.setImage(UIImage(named: "credit-card"), for: .normal)
        
        backButton.addTarget(self, action: #selector(seeAllButtonTapped), for: .touchUpInside)
        var leftBarButton = UIBarButtonItem(customView: backButton)
        navigationItem.leftBarButtonItem = leftBarButton
    }
    
    @objc
    func seeAllButtonTapped() {
        let vc = VaultedPaymentInstrumentsViewController()
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        vc.view.heightAnchor.constraint(equalToConstant: view.bounds.size.height).isActive = true
        Primer.shared.primerRootVC?.show(viewController: vc)
    }
        
    @objc
    func applePayButtonTapped(_ sender: UIButton) {
        let appleViewModel: ApplePayViewModelProtocol = DependencyContainer.resolve()
        appleViewModel.payWithApple { (err) in
            
        }
    }
    
    @objc
    func klarnaButtonTapped() {
        if #available(iOS 11.0, *) {
            let oavc = OAuthViewController(host: .klarna)
            oavc.modalPresentationStyle = .fullScreen
            present(oavc, animated: true, completion: nil)
        }
    }
    
    @objc
    func payPalButtonTapped() {
        if #available(iOS 11.0, *) {
            let oavc = OAuthViewController(host: .paypal)
            oavc.modalPresentationStyle = .fullScreen
            present(oavc, animated: true, completion: nil)
        }
    }
    
    @objc
    func cardButtonTapped() {
        let cfvc = PrimerCardFormViewController(flow: .checkout)
        Primer.shared.primerRootVC?.show(viewController: cfvc)
    }
    
}
