//
//  PrimerUniversalCheckoutViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 31/7/21.
//

import UIKit

internal class PrimerUniversalCheckoutViewController: PrimerFormViewController {
    
    var savedCardView: CardButton!
    private var titleLabel: UILabel!
    private var savedPaymentMethodStackView: UIStackView!
    private var payButton: PrimerButton!
    private var selectedPaymentInstrument: PaymentMethodToken?
    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    // swiftlint:disable function_body_length
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("primer-checkout-nav-bar-title",
                                          tableName: nil,
                                          bundle: Bundle.primerResources,
                                          value: "Choose payment method",
                                          comment: "Choose payment method - Checkout Navigation Bar Title")
        
        view.backgroundColor = theme.colorTheme.main1
        
        verticalStackView.spacing = 14.0
        
        renderAmount()
        renderSelectedPaymentInstrument()
        renderAvailablePaymentMethods()
    }
    
    private func renderAmount() {
        let checkoutViewModel: VaultCheckoutViewModelProtocol = DependencyContainer.resolve()
        
        if let amountStr = checkoutViewModel.amountStringed {
            titleLabel = UILabel()
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true
            titleLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
            titleLabel.text = amountStr
            titleLabel.textAlignment = .left
            titleLabel.textColor = theme.colorTheme.text1
            verticalStackView.addArrangedSubview(titleLabel)
        }
    }
    
    private func renderSelectedPaymentInstrument(insertAt index: Int? = nil) {
        if savedCardView != nil {
            verticalStackView.removeArrangedSubview(savedCardView)
            savedCardView.removeFromSuperview()
            savedCardView = nil
        }
        
        if savedPaymentMethodStackView != nil {
            verticalStackView.removeArrangedSubview(savedPaymentMethodStackView)
            savedPaymentMethodStackView.removeFromSuperview()
            savedPaymentMethodStackView = nil
        }
        
        let checkoutViewModel: VaultCheckoutViewModelProtocol = DependencyContainer.resolve()
        
        self.selectedPaymentInstrument = nil
        
        if let selectedPaymentInstrument = checkoutViewModel.paymentMethods.first(where: { paymentInstrument in
            return paymentInstrument.token == checkoutViewModel.selectedPaymentMethodId
        }), let cardButtonViewModel = selectedPaymentInstrument.cardButtonViewModel {
            
            self.selectedPaymentInstrument = selectedPaymentInstrument
            
            if savedPaymentMethodStackView == nil {
                savedPaymentMethodStackView = UIStackView()
                savedPaymentMethodStackView.axis = .vertical
                savedPaymentMethodStackView.alignment = .fill
                savedPaymentMethodStackView.distribution = .fill
                savedPaymentMethodStackView.spacing = 5.0
            }
            
            let titleHorizontalStackView = UIStackView()
            titleHorizontalStackView.axis = .horizontal
            titleHorizontalStackView.alignment = .fill
            titleHorizontalStackView.distribution = .fillProportionally
            titleHorizontalStackView.spacing = 8.0
            
            let savedPaymentMethodLabel = UILabel()
            savedPaymentMethodLabel.text = NSLocalizedString("primer-vault-checkout-payment-method-title",
                                                                      tableName: nil,
                                                                      bundle: Bundle.primerResources,
                                                                      value: "SAVED PAYMENT METHOD",
                                                                      comment: "SAVED PAYMENT METHOD - Vault Checkout Card Title")
            savedPaymentMethodLabel.textColor = theme.colorTheme.secondaryText1
            savedPaymentMethodLabel.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)
            savedPaymentMethodLabel.textAlignment = .left
            titleHorizontalStackView.addArrangedSubview(savedPaymentMethodLabel)
            
            let seeAllButton = UIButton()
            seeAllButton.translatesAutoresizingMaskIntoConstraints = false
            seeAllButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
            seeAllButton.setTitle("See all", for: .normal)
            seeAllButton.contentHorizontalAlignment = .right
            seeAllButton.setTitleColor(theme.colorTheme.text3, for: .normal)
            seeAllButton.addTarget(self, action: #selector(seeAllButtonTapped), for: .touchUpInside)
            titleHorizontalStackView.addArrangedSubview(seeAllButton)
            
            savedPaymentMethodStackView.addArrangedSubview(titleHorizontalStackView)
            
            let paymentMethodStackView = UIStackView()
            paymentMethodStackView.layer.cornerRadius = 4.0
            paymentMethodStackView.clipsToBounds = true
            paymentMethodStackView.backgroundColor = .black.withAlphaComponent(0.05)
            paymentMethodStackView.axis = .vertical
            paymentMethodStackView.alignment = .fill
            paymentMethodStackView.distribution = .fill
            paymentMethodStackView.spacing = 8.0
            paymentMethodStackView.isLayoutMarginsRelativeArrangement = true
            if #available(iOS 11.0, *) {
                paymentMethodStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
            }

            if let surCharge = cardButtonViewModel.surCharge {
                let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
                let surChargeLabel = UILabel()
                surChargeLabel.text = "+" + Int(surCharge).toCurrencyString(currency: settings.currency!)
                surChargeLabel.textColor = .black
                surChargeLabel.textAlignment = .right
                surChargeLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
                paymentMethodStackView.addArrangedSubview(surChargeLabel)
            }
            
            if savedCardView == nil {
                savedCardView = CardButton()
                savedCardView.backgroundColor = .white
                savedCardView.translatesAutoresizingMaskIntoConstraints = false
                savedCardView.heightAnchor.constraint(equalToConstant: 64.0).isActive = true
                savedCardView.render(model: cardButtonViewModel, showIcon: false)
                paymentMethodStackView.addArrangedSubview(savedCardView)
            }
            
            if payButton == nil {
                payButton = PrimerButton()
            }
            
            var buttonTitle = theme.content.vaultCheckout.payButtonText
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            
            var amount: Int = 0
            amount += settings.amount ?? 0
            
            amount += Int(cardButtonViewModel.surCharge ?? 0)
            
            if amount != 0, let currency = settings.currency {
                buttonTitle += " " + amount.toCurrencyString(currency: currency)
            }

            payButton.layer.cornerRadius = 4
            payButton.setTitle(buttonTitle, for: .normal)
            payButton.setTitleColor(theme.colorTheme.text2, for: .normal)
            payButton.titleLabel?.font = .boldSystemFont(ofSize: 19)
            payButton.backgroundColor = theme.colorTheme.main2
            payButton.addTarget(self, action: #selector(payButtonTapped), for: .touchUpInside)
            payButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
            paymentMethodStackView.addArrangedSubview(payButton)
            
            if !paymentMethodStackView.arrangedSubviews.isEmpty {
                savedPaymentMethodStackView.addArrangedSubview(paymentMethodStackView)
            }
            
            if let index = index {
                verticalStackView.insertArrangedSubview(savedPaymentMethodStackView, at: index)
            } else {
                verticalStackView.addArrangedSubview(savedPaymentMethodStackView)
            }
        } else {
            if savedCardView != nil {
                verticalStackView.removeArrangedSubview(savedCardView)
                savedCardView.removeFromSuperview()
                savedCardView = nil
            }
            
            if savedPaymentMethodStackView != nil {
                verticalStackView.removeArrangedSubview(savedPaymentMethodStackView)
                savedPaymentMethodStackView.removeFromSuperview()
                savedPaymentMethodStackView = nil
            }
        }
        
        verticalStackView.layoutIfNeeded()
        
        Primer.shared.primerRootVC?.layoutIfNeeded()
    }
    
    private func renderAvailablePaymentMethods() {
        let availablePaymentMethodsContainerStackView = UIStackView()
        availablePaymentMethodsContainerStackView.axis = .vertical
        availablePaymentMethodsContainerStackView.alignment = .fill
        availablePaymentMethodsContainerStackView.distribution = .fill
        availablePaymentMethodsContainerStackView.spacing = 5.0

        let state: AppStateProtocol = DependencyContainer.resolve()
        let availablePaymentMethods = state.paymentMethodConfig?.paymentMethods?.filter({ $0.type?.isEnabled == true }).compactMap({ PaymentMethodViewModel(type: $0.type!) }) ?? []
        
        if !availablePaymentMethods.isEmpty {
            let otherPaymentMethodsTitleLabel = UILabel()
            otherPaymentMethodsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
            otherPaymentMethodsTitleLabel.heightAnchor.constraint(equalToConstant: 16).isActive = true
            otherPaymentMethodsTitleLabel.text = NSLocalizedString("primer-vault-payment-method-available-payment-methods",
                                                                   tableName: nil,
                                                                   bundle: Bundle.primerResources,
                                                                   value: "Available payment methods",
                                                                   comment: "Available payment methods - Vault Checkout 'Available payment methods' Title").uppercased()
            otherPaymentMethodsTitleLabel.textColor = theme.colorTheme.secondaryText1
            otherPaymentMethodsTitleLabel.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)
            otherPaymentMethodsTitleLabel.textAlignment = .left
            
            availablePaymentMethodsContainerStackView.addArrangedSubview(otherPaymentMethodsTitleLabel)
            
            let availablePaymentMethodsStackView = UIStackView()
            availablePaymentMethodsStackView.axis = .vertical
            availablePaymentMethodsStackView.alignment = .fill
            availablePaymentMethodsStackView.distribution = .fill
            availablePaymentMethodsStackView.spacing = 10.0
            
            let noAdditionalFeePaymentMethodsViewModels = availablePaymentMethods.filter({ $0.surCharge == nil })
            
            if !noAdditionalFeePaymentMethodsViewModels.isEmpty {
                let noAdditionalFeesContainerView = PaymentMethodsGroupView(frame: .zero, title: "No additional fee", paymentMethodsViewModels: noAdditionalFeePaymentMethodsViewModels)
                noAdditionalFeesContainerView.titleLabel?.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)
                noAdditionalFeesContainerView.delegate = self
                availablePaymentMethodsStackView.addArrangedSubview(noAdditionalFeesContainerView)
            }
            
            let additionalFeePaymentMethodsViewModels = availablePaymentMethods.filter({ $0.surCharge != nil })
            
            if !additionalFeePaymentMethodsViewModels.isEmpty {
                for additionalFeePaymentMethodsViewModel in additionalFeePaymentMethodsViewModels {
                    let title = additionalFeePaymentMethodsViewModel.surCharge
                    let additionalFeesContainerView = PaymentMethodsGroupView(frame: .zero, title: title, paymentMethodsViewModels: [additionalFeePaymentMethodsViewModel])
                    additionalFeesContainerView.titleLabel?.font = title == "Additional fee may apply" ? UIFont.systemFont(ofSize: 12.0, weight: .regular) : UIFont.systemFont(ofSize: 16.0, weight: .bold)
                    additionalFeesContainerView.delegate = self
                    availablePaymentMethodsStackView.addArrangedSubview(additionalFeesContainerView)
                }
            }
            
            availablePaymentMethodsContainerStackView.addArrangedSubview(availablePaymentMethodsStackView)
        }
        
        verticalStackView.addArrangedSubview(availablePaymentMethodsContainerStackView)
    }
    
    @objc
    func seeAllButtonTapped() {
        let vpivc = VaultedPaymentInstrumentsViewController()
        vpivc.delegate = self
        vpivc.view.translatesAutoresizingMaskIntoConstraints = false
        vpivc.view.heightAnchor.constraint(equalToConstant: view.bounds.size.height).isActive = true
        Primer.shared.primerRootVC?.show(viewController: vpivc)
    }
        
    @objc
    func applePayButtonTapped() {
        let action = ClientSession.Action(
            type: "SELECT_PAYMENT_METHOD",
            params: [
                "type": "APPLE_PAY"
            ])
        
        Primer.shared.delegate?.onClientSessionActionsCreated?([action], completion: { clientToken, err in
            if let clientToken = clientToken {
                try! ClientTokenService.storeClientToken(clientToken)
                let config: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
                config.fetchConfig { err in
                    let state: AppStateProtocol = DependencyContainer.resolve()
                    Primer.shared.primerRootVC?.presentApplePay()
                }
            }
        })
        
        let lvc = PrimerLoadingViewController(withHeight: 300)
        Primer.shared.primerRootVC?.show(viewController: lvc)
    }
    
    @objc
    func klarnaButtonTapped() {
        let action = ClientSession.Action(
            type: "SELECT_PAYMENT_METHOD",
            params: [
                "type": "KLARNA"
            ])
        
        Primer.shared.delegate?.onClientSessionActionsCreated?([action], completion: { clientToken, err in
            if let clientToken = clientToken {
                try! ClientTokenService.storeClientToken(clientToken)
                let config: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
                config.fetchConfig { err in
                    let state: AppStateProtocol = DependencyContainer.resolve()
                    print(state.paymentMethodConfig)
                    Primer.shared.primerRootVC?.presentKlarna()
                }
            }
        })
        
        let lvc = PrimerLoadingViewController(withHeight: 300)
        Primer.shared.primerRootVC?.show(viewController: lvc)
    }
    
    @objc
    func payPalButtonTapped() {
        if #available(iOS 11.0, *) {
            let action = ClientSession.Action(
                type: "SELECT_PAYMENT_METHOD",
                params: [
                    "type": "PAYPAL"
                ])
            
            Primer.shared.delegate?.onClientSessionActionsCreated?([action], completion: { clientToken, err in
                if let clientToken = clientToken {
                    try! ClientTokenService.storeClientToken(clientToken)
                    let config: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
                    config.fetchConfig { err in
                        let state: AppStateProtocol = DependencyContainer.resolve()
                        print(state.paymentMethodConfig)
                        Primer.shared.primerRootVC?.presentPayPal()
                    }
                }
            })
            
            let lvc = PrimerLoadingViewController(withHeight: 300)
            Primer.shared.primerRootVC?.show(viewController: lvc)
        }
    }
    
    @objc
    func cardButtonTapped() {
        if #available(iOS 11.0, *) {
            let action = ClientSession.Action(
                type: "SELECT_PAYMENT_METHOD",
                params: [
                    "type": "PAYMENT_CARD"
                ])
            
            Primer.shared.delegate?.onClientSessionActionsCreated?([action], completion: { clientToken, err in
                if let clientToken = clientToken {
                    try! ClientTokenService.storeClientToken(clientToken)
                    let config: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
                    config.fetchConfig { err in
                        let state: AppStateProtocol = DependencyContainer.resolve()
                        print(state.paymentMethodConfig)
                        
                        let cfvc = PrimerCardFormViewController(flow: .checkout)
                        Primer.shared.primerRootVC?.show(viewController: cfvc)
                    }
                }
            })
            
            let lvc = PrimerLoadingViewController(withHeight: 300)
            Primer.shared.primerRootVC?.show(viewController: lvc)
        }
    }
    
    @objc
    func payButtonTapped() {
        guard let paymentMethodToken = selectedPaymentInstrument else { return }
        
        enableView(false)
        
        payButton.showSpinner(true, color: theme.colorTheme.text2)
        Primer.shared.delegate?.onTokenizeSuccess?(paymentMethodToken, { err in
            DispatchQueue.main.async { [weak self] in
                self?.payButton.showSpinner(false)
                self?.enableView(true)

                let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
                
                if settings.hasDisabledSuccessScreen {
                    Primer.shared.dismiss()
                } else {
                    if let err = err {
                        let evc = ErrorViewController(message: err.localizedDescription)
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
        Primer.shared.delegate?.onTokenizeSuccess?(paymentMethodToken, resumeHandler: self)
    }
    
    // MARK: - Helpers
    
    private func enableView(_ isEnabled: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.view?.isUserInteractionEnabled = !isEnabled
            
            for sv in (self?.verticalStackView.arrangedSubviews ?? []) {
                sv.alpha = sv == self?.savedPaymentMethodStackView ? 1.0 : (isEnabled ? 1.0 : 0.5)
            }
            
            for sv in (self?.savedPaymentMethodStackView.arrangedSubviews ?? []) {
                if let stackView = sv as? UIStackView, !stackView.arrangedSubviews.filter({ $0 is PrimerButton }).isEmpty {
                    for ssv in stackView.arrangedSubviews {
                        if ssv is PrimerButton {
                            ssv.alpha = 1.0
                        } else {
                            ssv.alpha = (isEnabled ? 1.0 : 0.5)
                        }
                    }
                } else {
                    sv.alpha = (isEnabled ? 1.0 : 0.5)
                }
            }
        }
    }
    
}

extension PrimerUniversalCheckoutViewController: ResumeHandlerProtocol {
    func handle(error: Error) {
        DispatchQueue.main.async {
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            
            if !settings.hasDisabledSuccessScreen {
                let evc = ErrorViewController(message: PrimerError.failedToLoadSession.localizedDescription)
                evc.view.translatesAutoresizingMaskIntoConstraints = false
                evc.view.heightAnchor.constraint(equalToConstant: 300).isActive = true
                Primer.shared.primerRootVC?.show(viewController: evc)
            } else {
                Primer.shared.dismiss()
            }
        }
    }
    
    func handle(newClientToken clientToken: String) {
        try? ClientTokenService.storeClientToken(clientToken)
    }
    
    func handleSuccess() {
        DispatchQueue.main.async { 
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

            if settings.hasDisabledSuccessScreen {
                Primer.shared.dismiss()
            } else {
                let svc = SuccessViewController()
                svc.view.translatesAutoresizingMaskIntoConstraints = false
                svc.view.heightAnchor.constraint(equalToConstant: 300).isActive = true
                Primer.shared.primerRootVC?.show(viewController: svc)
            }
        }
    }
}

extension PrimerUniversalCheckoutViewController: ReloadDelegate {
    func reload() {
        renderSelectedPaymentInstrument(insertAt: 1)
    }
}

extension PrimerUniversalCheckoutViewController: PaymentMethodsGroupViewDelegate {
    func paymentMethodsGroupView(_ paymentMethodsGroupView: PaymentMethodsGroupView, paymentMethodTapped paymentMethod: PaymentMethodViewModel) {
        switch  paymentMethod.type {
        case .applePay:
            applePayButtonTapped()
        case .apaya:
            break
        case .payPal:
            payPalButtonTapped()
        case .paymentCard:
            cardButtonTapped()
        case .googlePay:
            break
        case .goCardlessMandate:
            break
        case .klarna:
            klarnaButtonTapped()
        case .payNlIdeal:
            break
        case .unknown:
            break
        }
    }
}
