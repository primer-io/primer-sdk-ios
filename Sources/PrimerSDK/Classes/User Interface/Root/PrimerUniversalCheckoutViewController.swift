//
//  PrimerUniversalCheckoutViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 31/7/21.
//

#if canImport(UIKit)

import UIKit

internal class PrimerUniversalCheckoutViewController: PrimerFormViewController {
    
    var savedCardView: CardButton!
    private var titleLabel: UILabel!
    private var savedPaymentMethodStackView: UIStackView!
    private var payButton: PrimerOldButton!
    private var selectedPaymentMethod: PaymentMethodToken?
    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    private let paymentMethodConfigViewModels = PrimerConfiguration.paymentMethodConfigViewModels
    private var onClientSessionActionCompletion: ((Error?) -> Void)?
    private var singleUsePaymentMethod: PaymentMethodToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let viewEvent = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .view,
                context: nil,
                extra: nil,
                objectType: .view,
                objectId: nil,
                objectClass: "\(Self.self)",
                place: .universalCheckout))
        Analytics.Service.record(event: viewEvent)
        
        title = NSLocalizedString("primer-checkout-nav-bar-title",
                                          tableName: nil,
                                          bundle: Bundle.primerResources,
                                          value: "Choose payment method",
                                          comment: "Choose payment method - Checkout Navigation Bar Title")
        
        view.backgroundColor = theme.view.backgroundColor
        
        verticalStackView.spacing = 14.0
        
        renderAmount()
        renderSelectedPaymentInstrument()
        renderAvailablePaymentMethods()
        
        guard ClientTokenService.decodedClientToken.exists else { return }
        let vaultService: VaultServiceProtocol = DependencyContainer.resolve()
        vaultService.loadVaultedPaymentMethods { err in
            self.renderSelectedPaymentInstrument(insertAt: 1)
        }
    }
    
    private func renderAmount() {
        let checkoutViewModel: VaultCheckoutViewModelProtocol = DependencyContainer.resolve()
        
        if let amountStr = checkoutViewModel.amountStringed {
            titleLabel = UILabel()
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true
            titleLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
            titleLabel.text = amountStr
            titleLabel.textColor = theme.text.amountLabel.color
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
        
        if let selectedPaymentMethod = checkoutViewModel.selectedPaymentMethod, let cardButtonViewModel = selectedPaymentMethod.cardButtonViewModel {
            
            self.selectedPaymentMethod = selectedPaymentMethod
            
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
            titleHorizontalStackView.distribution = .fill
            titleHorizontalStackView.spacing = 8.0
            
            let savedPaymentMethodLabel = UILabel()
            savedPaymentMethodLabel.text = NSLocalizedString("primer-vault-checkout-payment-method-title",
                                                                      tableName: nil,
                                                                      bundle: Bundle.primerResources,
                                                                      value: "SAVED PAYMENT METHOD",
                                                                      comment: "SAVED PAYMENT METHOD - Vault Checkout Card Title")
            savedPaymentMethodLabel.adjustsFontSizeToFitWidth = true
            savedPaymentMethodLabel.minimumScaleFactor = 0.8
            savedPaymentMethodLabel.textColor = theme.text.subtitle.color
            savedPaymentMethodLabel.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)
            titleHorizontalStackView.addArrangedSubview(savedPaymentMethodLabel)
            
            let seeAllButton = UIButton()
            seeAllButton.translatesAutoresizingMaskIntoConstraints = false
            seeAllButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
            
            let seeAllButtonTitle = NSLocalizedString("see-all",
                                                      tableName: nil,
                                                      bundle: Bundle.primerResources,
                                                      value: "See all",
                                                      comment: "See all - Universal checkout")
            seeAllButton.setTitle(seeAllButtonTitle, for: .normal)
            seeAllButton.titleLabel?.adjustsFontSizeToFitWidth = true
            seeAllButton.titleLabel?.minimumScaleFactor = 0.7
            seeAllButton.setTitleColor(theme.text.system.color, for: .normal)
            seeAllButton.addTarget(self, action: #selector(seeAllButtonTapped), for: .touchUpInside)
            titleHorizontalStackView.addArrangedSubview(seeAllButton)
            
            savedPaymentMethodStackView.addArrangedSubview(titleHorizontalStackView)
            
            let paymentMethodStackView = UIStackView()
            paymentMethodStackView.layer.cornerRadius = 4.0
            paymentMethodStackView.clipsToBounds = true
            paymentMethodStackView.backgroundColor = UIColor.black.withAlphaComponent(0.05)
            paymentMethodStackView.axis = .vertical
            paymentMethodStackView.alignment = .fill
            paymentMethodStackView.distribution = .fill
            paymentMethodStackView.spacing = 8.0
            paymentMethodStackView.isLayoutMarginsRelativeArrangement = true
            if #available(iOS 11.0, *) {
                paymentMethodStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
            }

            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            var amount: Int = settings.amount ?? 0
            
            if let surCharge = cardButtonViewModel.surCharge {
                let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
                let theme: PrimerThemeProtocol = DependencyContainer.resolve()
                
                let surChargeLabel = UILabel()
                surChargeLabel.text = "+" + Int(surCharge).toCurrencyString(currency: settings.currency!)
                surChargeLabel.textColor = theme.text.body.color
                surChargeLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
                paymentMethodStackView.addArrangedSubview(surChargeLabel)
                
                amount += surCharge
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
                payButton = PrimerOldButton()
            }

            var title = NSLocalizedString("primer-form-view-card-submit-button-text-checkout",
                                          tableName: nil,
                                          bundle: Bundle.primerResources,
                                          value: "Pay",
                                          comment: "Pay - Card Form View (Sumbit button text)") //+ " " + (amount.toCurrencyString(currency: settings.currency) ?? "")
            
            if amount != 0, let currency = settings.currency {
                title += " \(amount.toCurrencyString(currency: currency))"
            }
                                    
            payButton.layer.cornerRadius = 4
            payButton.setTitle(title, for: .normal)
            payButton.setTitleColor(theme.mainButton.text.color, for: .normal)
            payButton.titleLabel?.font = .boldSystemFont(ofSize: 19)
            payButton.backgroundColor = theme.mainButton.color(for: .enabled)
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
        
        (self.parent as? PrimerContainerViewController)?.layoutContainerViewControllerIfNeeded {
            self.verticalStackView.layoutIfNeeded()
        }
        
        Primer.shared.primerRootVC?.layoutIfNeeded()
    }

    private func renderAvailablePaymentMethods() {
        PrimerFormViewController.renderPaymentMethods(paymentMethodConfigViewModels, on: verticalStackView)
    }

    @objc
    func seeAllButtonTapped(_ sender: Any) {
        let uiEvent = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .click,
                context: nil,
                extra: nil,
                objectType: .button,
                objectId: .seeAll,
                objectClass: "\(Self.self)",
                place: .universalCheckout))
        Analytics.Service.record(event: uiEvent)
        
        let vpivc = VaultedPaymentInstrumentsViewController()
        vpivc.delegate = self
        vpivc.view.translatesAutoresizingMaskIntoConstraints = false
        vpivc.view.heightAnchor.constraint(equalToConstant: self.parent!.view.bounds.height).isActive = true
        Primer.shared.primerRootVC?.show(viewController: vpivc)
    }
    
    @objc
    func payButtonTapped() {
        guard let selectedPaymentMethod = selectedPaymentMethod else { return }
        guard let config = PrimerConfiguration.paymentMethodConfigs?.filter({ $0.type.rawValue == selectedPaymentMethod.paymentInstrumentType.rawValue }).first else {
            return
        }
        
        let viewEvent = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .click,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: config.type.rawValue,
                    url: nil),
                extra: nil,
                objectType: .button,
                objectId: .pay,
                objectClass: "\(Self.self)",
                place: .universalCheckout))
        Analytics.Service.record(event: viewEvent)
        
        enableView(false)
        payButton.showSpinner(true)
        
        if PrimerDelegateProxy.isClientSessionActionsImplemented {
            var params: [String: Any] = ["paymentMethodType": config.type.rawValue]
            if config.type == .paymentCard {
                var network = selectedPaymentMethod.paymentInstrumentData?.network?.uppercased()
                if network == nil || network == "UNKNOWN" {
                    network = "OTHER"
                }
                
                params = [
                    "paymentMethodType": "PAYMENT_CARD",
                    "binData": [
                        "network": network,
                    ]
                ]
            }
            
            onClientSessionActionCompletion = { err in
                if let err = err {
                    DispatchQueue.main.async {
                        ClientSession.Action.unselectPaymentMethod(resumeHandler: nil)
                        PrimerDelegateProxy.onResumeError(err)
                        self.onClientSessionActionCompletion = nil
                    }
                } else {
                    self.continuePayment(withVaultedPaymentMethod: selectedPaymentMethod)
                }
            }
            
            ClientSession.Action.selectPaymentMethod(resumeHandler: self, withParameters: params)
            
        } else {
            continuePayment(withVaultedPaymentMethod: selectedPaymentMethod)
        }
    }
    
    private func continuePayment(withVaultedPaymentMethod paymentMethodToken: PaymentMethodToken) {
        guard let decodedClientToken = ClientTokenService.decodedClientToken else { return }
        let client: PrimerAPIClientProtocol = DependencyContainer.resolve()
        client.exchangePaymentMethodToken(clientToken: decodedClientToken, paymentMethodId: paymentMethodToken.id!) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let singleUsePaymentMethod):
                    self.singleUsePaymentMethod = singleUsePaymentMethod
                    PrimerDelegateProxy.onTokenizeSuccess(singleUsePaymentMethod, { err in
                        DispatchQueue.main.async { [weak self] in
                            self?.payButton.showSpinner(false)
                            self?.enableView(true)

                            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

                            if settings.hasDisabledSuccessScreen {
                                Primer.shared.dismiss()
                                self?.singleUsePaymentMethod = nil
                            } else {
                                if let err = err {
                                    let evc = PrimerResultViewController(screenType: .failure, message: err.localizedDescription) //ErrorViewController(message: err.localizedDescription)
                                    evc.view.translatesAutoresizingMaskIntoConstraints = false
                                    evc.view.heightAnchor.constraint(equalToConstant: 300.0).isActive = true
                                    Primer.shared.primerRootVC?.show(viewController: evc)
                                } else {
                                    let svc = PrimerResultViewController(screenType: .success, message: nil)
                                    svc.view.translatesAutoresizingMaskIntoConstraints = false
                                    svc.view.heightAnchor.constraint(equalToConstant: 300.0).isActive = true
                                    Primer.shared.primerRootVC?.show(viewController: svc)
                                }
                                self?.singleUsePaymentMethod = nil
                            }
                        }
                    })
                    
                    PrimerDelegateProxy.onTokenizeSuccess(singleUsePaymentMethod, resumeHandler: self)
                case .failure(let err):
                    PrimerDelegateProxy.checkoutFailed(with: err)
                    let evc = PrimerResultViewController(screenType: .failure, message: err.localizedDescription)
                    evc.view.translatesAutoresizingMaskIntoConstraints = false
                    evc.view.heightAnchor.constraint(equalToConstant: 300.0).isActive = true
                    Primer.shared.primerRootVC?.show(viewController: evc)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func enableView(_ isEnabled: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.view?.isUserInteractionEnabled = isEnabled
            (self?.parent as? PrimerContainerViewController)?.scrollView.isScrollEnabled = isEnabled
            Primer.shared.primerRootVC?.swipeGesture?.isEnabled = isEnabled
            
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
            self.onClientSessionActionCompletion?(error)
            
            self.payButton.showSpinner(false)
            self.enableView(true)
            
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            
            if !settings.hasDisabledSuccessScreen {
                let evc = PrimerResultViewController(screenType: .failure, message: error.localizedDescription)
                evc.view.translatesAutoresizingMaskIntoConstraints = false
                evc.view.heightAnchor.constraint(equalToConstant: 300).isActive = true
                Primer.shared.primerRootVC?.show(viewController: evc)
            } else {
                Primer.shared.dismiss()
            }
            
            self.singleUsePaymentMethod = nil
        }
    }
    
    func handle(newClientToken clientToken: String) {
        do {
            let state: AppStateProtocol = DependencyContainer.resolve()
            
            if state.clientToken != clientToken {
                try ClientTokenService.storeClientToken(clientToken)
            }
            
            let decodedClientToken = ClientTokenService.decodedClientToken!
            
            if decodedClientToken.intent == RequiredActionName.threeDSAuthentication.rawValue {
                #if canImport(Primer3DS)
                guard let paymentMethod = singleUsePaymentMethod else {
                    DispatchQueue.main.async {
                        self.onClientSessionActionCompletion = nil
                        let err = PrimerError.invalid3DSKey(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                        ErrorHandler.handle(error: err)
                        PrimerDelegateProxy.onResumeError(err)
                        self.handle(error: err)
                    }
                    return
                }
                
                let threeDSService = ThreeDSService()
                threeDSService.perform3DS(paymentMethodToken: paymentMethod, protocolVersion: ClientTokenService.decodedClientToken?.env == "PRODUCTION" ? .v1 : .v2, sdkDismissed: nil) { result in
                    switch result {
                    case .success(let paymentMethodToken):
                        DispatchQueue.main.async {
                            guard let threeDSPostAuthResponse = paymentMethodToken.1,
                                  let resumeToken = threeDSPostAuthResponse.resumeToken else {
                                      DispatchQueue.main.async {
                                          self.onClientSessionActionCompletion = nil
                                          let err = ParserError.failedToDecode(message: "Failed to decode the threeDSPostAuthResponse", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                                          ErrorHandler.handle(error: err)
                                          PrimerDelegateProxy.onResumeError(err)
                                          self.handle(error: err)
                                      }
                                      return
                                  }
                            
                            PrimerDelegateProxy.onResumeSuccess(resumeToken, resumeHandler: self)
                        }
                        
                    case .failure(let err):
                        log(logLevel: .error, message: "Failed to perform 3DS with error \(err as NSError)")
                        
                        DispatchQueue.main.async {
                            self.onClientSessionActionCompletion = nil
                            let containerErr = PrimerError.failedToPerform3DS(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                            ErrorHandler.handle(error: containerErr)
                            PrimerDelegateProxy.onResumeError(containerErr)
                            self.handle(error: err)
                        }
                    }
                }
                #else
                
                DispatchQueue.main.async {
                    self.onClientSessionActionCompletion = nil
                    let err = PrimerError.failedToPerform3DS(error: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: err)
                    PrimerDelegateProxy.onResumeError(err)
                    self.handle(error: err)
                }
                #endif
                
            } else if decodedClientToken.intent == RequiredActionName.checkout.rawValue {
                let configService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
                
                firstly {
                    configService.fetchConfig()
                }
                .done {
                    self.onClientSessionActionCompletion?(nil)
                }
                .catch { err in
                    self.handle(error: err)
                }
            } else {
                let err = PrimerError.invalidValue(key: "resumeToken", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                handle(error: err)
                DispatchQueue.main.async {
                    PrimerDelegateProxy.onResumeError(err)
                }
            }
            
        } catch {
            handle(error: error)
            DispatchQueue.main.async {
                PrimerDelegateProxy.onResumeError(error)
            }
        }
    }
    
    func handleSuccess() {
        DispatchQueue.main.async {
            self.payButton.showSpinner(false)
            self.enableView(true)
            
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

            if settings.hasDisabledSuccessScreen {
                Primer.shared.dismiss()
            } else {
                let svc = PrimerResultViewController(screenType: .success, message: nil)
                svc.view.translatesAutoresizingMaskIntoConstraints = false
                svc.view.heightAnchor.constraint(equalToConstant: 300).isActive = true
                Primer.shared.primerRootVC?.show(viewController: svc)
            }
            
            self.singleUsePaymentMethod = nil
        }
    }
}

extension PrimerUniversalCheckoutViewController: ReloadDelegate {
    func reload() {
        renderSelectedPaymentInstrument(insertAt: 1)
    }
}

#endif
