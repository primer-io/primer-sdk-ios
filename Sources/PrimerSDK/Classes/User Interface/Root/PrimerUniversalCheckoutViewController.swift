//
//  PrimerUniversalCheckoutViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 31/7/21.
//

import UIKit

internal class PrimerUniversalCheckoutViewController: PrimerFormViewController {
    
    var savedCardButtonView: CardButton!
    private var seeAllButton: UIButton!
    private var savedPaymentInstrumentStackView: UIStackView!
    
    // swiftlint:disable function_body_length
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .blue
        title = NSLocalizedString("primer-checkout-nav-bar-title",
                                          tableName: nil,
                                          bundle: Bundle.primerResources,
                                          value: "Choose payment method",
                                          comment: "Choose payment method - Checkout Navigation Bar Title")
        
        view.backgroundColor = .white
        
        verticalStackView.spacing = 14.0
        
        renderAmount()
        renderSelectedPaymentInstrument()
        renderAvailablePaymentMethods()
    }
    
    private func renderAmount() {
        let checkoutViewModel: VaultCheckoutViewModelProtocol = DependencyContainer.resolve()
        
        if let amountStr = checkoutViewModel.amountStringed {
            let titleLabel = UILabel()
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true
            titleLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
            titleLabel.text = amountStr
            titleLabel.textAlignment = .left
            verticalStackView.addArrangedSubview(titleLabel)
        }
    }
    
    private func renderSelectedPaymentInstrument(insertAt index: Int? = nil) {
        if seeAllButton != nil {
            verticalStackView.removeArrangedSubview(seeAllButton)
            seeAllButton.removeFromSuperview()
            seeAllButton = nil
        }
        
        if savedCardButtonView != nil {
            verticalStackView.removeArrangedSubview(savedCardButtonView)
            savedCardButtonView.removeFromSuperview()
            savedCardButtonView = nil
        }
        
        if savedPaymentInstrumentStackView != nil {
            verticalStackView.removeArrangedSubview(savedPaymentInstrumentStackView)
            savedPaymentInstrumentStackView.removeFromSuperview()
            savedPaymentInstrumentStackView = nil
        }
        
        let checkoutViewModel: VaultCheckoutViewModelProtocol = DependencyContainer.resolve()
        
        if let selectedPaymentInstrument = checkoutViewModel.paymentMethods.first(where: { paymentInstrument in
            return paymentInstrument.token == checkoutViewModel.selectedPaymentMethodId
        }), let cardButtonViewModel = selectedPaymentInstrument.cardButtonViewModel {
            if savedPaymentInstrumentStackView == nil {
                savedPaymentInstrumentStackView = UIStackView()
                savedPaymentInstrumentStackView.axis = .vertical
                savedPaymentInstrumentStackView.alignment = .fill
                savedPaymentInstrumentStackView.distribution = .fill
                savedPaymentInstrumentStackView.spacing = verticalStackView.spacing
            }
            
            let savedPaymentInstrumentTitleLabel = UILabel()
            savedPaymentInstrumentTitleLabel.text = NSLocalizedString("primer-vault-checkout-payment-method-title",
                                                                      tableName: nil,
                                                                      bundle: Bundle.primerResources,
                                                                      value: "SAVED PAYMENT METHOD",
                                                                      comment: "SAVED PAYMENT METHOD - Vault Checkout Card Title")
            savedPaymentInstrumentTitleLabel.textColor = PrimerColor(rgb: 0x808080)
            savedPaymentInstrumentTitleLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .regular)
            savedPaymentInstrumentTitleLabel.textAlignment = .left
            savedPaymentInstrumentStackView.addArrangedSubview(savedPaymentInstrumentTitleLabel)
            
            if savedCardButtonView == nil {
                savedCardButtonView = CardButton()
                savedPaymentInstrumentStackView.addArrangedSubview(savedCardButtonView)
                savedCardButtonView.translatesAutoresizingMaskIntoConstraints = false
                savedCardButtonView.heightAnchor.constraint(equalToConstant: 64.0).isActive = true
                savedCardButtonView.render(model: cardButtonViewModel, showIcon: false)
            }
            
            if seeAllButton == nil {
                seeAllButton = UIButton()
                seeAllButton.translatesAutoresizingMaskIntoConstraints = false
                seeAllButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
                seeAllButton.setTitle("See all", for: .normal)
                seeAllButton.setTitleColor(PrimerColor(rgb: 0x007AFF), for: .normal)
                seeAllButton.addTarget(self, action: #selector(seeAllButtonTapped), for: .touchUpInside)
                savedPaymentInstrumentStackView.addArrangedSubview(seeAllButton)
            }
            
            if let index = index {
                verticalStackView.insertArrangedSubview(savedPaymentInstrumentStackView, at: index)
            } else {
                verticalStackView.addArrangedSubview(savedPaymentInstrumentStackView)
            }
        } else {
            if savedCardButtonView != nil {
                verticalStackView.removeArrangedSubview(savedCardButtonView)
                savedCardButtonView.removeFromSuperview()
                savedCardButtonView = nil
            }
            
            if seeAllButton != nil {
                verticalStackView.removeArrangedSubview(seeAllButton)
                seeAllButton.removeFromSuperview()
                seeAllButton = nil
            }
            
            if savedPaymentInstrumentStackView != nil {
                verticalStackView.removeArrangedSubview(savedPaymentInstrumentStackView)
                savedPaymentInstrumentStackView.removeFromSuperview()
                savedPaymentInstrumentStackView = nil
            }
        }
        
        verticalStackView.layoutIfNeeded()
        
        Primer.shared.primerRootVC?.layoutIfNeeded()
    }
    
    private func renderAvailablePaymentMethods() {
        let checkoutViewModel: VaultCheckoutViewModelProtocol = DependencyContainer.resolve()
        let availablePaymentMethods = checkoutViewModel.availablePaymentOptions
        
        if !availablePaymentMethods.filter({ $0.type != .googlePay }).isEmpty {
            let otherPaymentMethodsTitleLabel = UILabel()
            otherPaymentMethodsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
            otherPaymentMethodsTitleLabel.heightAnchor.constraint(equalToConstant: 16).isActive = true
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
                    paymentMethodButton.setTitleColor(.black, for: .normal)
                    paymentMethodButton.tintColor = .black
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
    }
    
    @objc
    func seeAllButtonTapped() {
//        let vc = VaultPaymentMethodViewController()
//        vc.view.translatesAutoresizingMaskIntoConstraints = false
//        vc.view.heightAnchor.constraint(equalToConstant: 400).isActive = true
//        Primer.shared.primerRootVC?.show(viewController: vc)
        
        let vc = VaultedPaymentInstrumentsViewController()
        vc.delegate = self
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
        let lvc = PrimerLoadingViewController(withHeight: 300)
        Primer.shared.primerRootVC?.show(viewController: lvc)
        Primer.shared.primerRootVC?.presentKlarna()
    }
    
    @objc
    func payPalButtonTapped() {
        let lvc = PrimerLoadingViewController(withHeight: 300)
        Primer.shared.primerRootVC?.show(viewController: lvc)
        
        let viewModel: OAuthViewModelProtocol = DependencyContainer.resolve()
        viewModel.generateOAuthURL(.paypal, with: { [weak self] result in
            DispatchQueue.main.async {
                let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
                
                switch result {
                case .failure(let error):
                    _ = ErrorHandler.shared.handle(error: error)
                    Primer.shared.delegate?.checkoutFailed?(with: error)

                    if settings.hasDisabledSuccessScreen {
                        Primer.shared.dismissPrimer()
                    } else {
                        let svc = ErrorViewController(message: error.localizedDescription)
                        svc.view.translatesAutoresizingMaskIntoConstraints = false
                        svc.view.heightAnchor.constraint(equalToConstant: 300.0).isActive = true
                        Primer.shared.primerRootVC?.show(viewController: svc)
                    }
                    
                case .success(let urlString):
                    self?.presentWebview(urlString)
                }
            }
        })
    }
    
    @objc
    func cardButtonTapped() {
        let cfvc = PrimerCardFormViewController(flow: .checkout)
        Primer.shared.primerRootVC?.show(viewController: cfvc)
    }
    
    private func presentWebview(_ urlString: String) {
        let webViewController = WebViewController()
        webViewController.url = URL(string: urlString)
        webViewController.klarnaWebViewCompletion = { [weak self] (_, err) in
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            
            DispatchQueue.main.async {
                if let err = err {
                    _ = ErrorHandler.shared.handle(error: err)
                    Primer.shared.primerRootVC?.dismiss(animated: true, completion: nil)
                    
                    if settings.hasDisabledSuccessScreen {
                        Primer.shared.dismissPrimer()
                    } else {
                        let evc = ErrorViewController(message: PrimerError.failedToLoadSession.localizedDescription)
                        evc.view.translatesAutoresizingMaskIntoConstraints = false
                        evc.view.heightAnchor.constraint(equalToConstant: 300.0).isActive = true
                        Primer.shared.primerRootVC?.show(viewController: evc)
                    }
                    
                } else {
                    let viewModel: OAuthViewModelProtocol = DependencyContainer.resolve()
                    viewModel.tokenize(.klarna, with: { err in
                        DispatchQueue.main.async {
                            Primer.shared.primerRootVC?.dismiss(animated: true, completion: nil)
                            
                            if settings.hasDisabledSuccessScreen {
                                Primer.shared.dismissPrimer()
                            } else {
                                if err != nil {
                                    let evc = ErrorViewController(message: PrimerError.failedToLoadSession.localizedDescription)
                                    evc.view.translatesAutoresizingMaskIntoConstraints = false
                                    evc.view.heightAnchor.constraint(equalToConstant: 300.0).isActive = true
                                    Primer.shared.primerRootVC?.show(viewController: evc)
                                    
                                } else {
                                    let svc = SuccessViewController()
                                    svc.view.translatesAutoresizingMaskIntoConstraints = false
                                    svc.view.heightAnchor.constraint(equalToConstant: 300.0).isActive = true
                                    Primer.shared.primerRootVC?.show(viewController: svc)
                                }
                                
                            }
                        }
                    })
                }
            }
        }
        
        webViewController.modalPresentationStyle = .overFullScreen
        Primer.shared.primerRootVC?.present(webViewController, animated: true, completion: nil)
    }
}

extension PrimerUniversalCheckoutViewController: ReloadDelegate {
    func reload() {
        renderSelectedPaymentInstrument(insertAt: 1)
    }
}
