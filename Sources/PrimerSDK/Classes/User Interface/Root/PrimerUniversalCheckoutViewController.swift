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
    private var payButton: PrimerButton!
    private var selectedPaymentMethod: PrimerPaymentMethodTokenData?
    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    private let paymentMethodConfigViewModels = PrimerAPIConfiguration.paymentMethodConfigViewModels
    private var onClientSessionActionUpdateCompletion: ((Error?) -> Void)?
    private var singleUsePaymentMethod: PrimerPaymentMethodTokenData?
    private var resumePaymentId: String?
    
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
        
        title = Strings.CheckoutView.navBarTitle
        view.backgroundColor = theme.view.backgroundColor
        
        verticalStackView.spacing = 14.0
        
        renderAmount()
        renderSelectedPaymentInstrument()
        renderAvailablePaymentMethods()
        
        guard ClientTokenService.decodedClientToken.exists else { return }
        let vaultService: VaultServiceProtocol = DependencyContainer.resolve()
        vaultService.loadVaultedPaymentMethods { [weak self] error in
            guard error == nil else {
                var primerErr: PrimerError!
                if let error = error as? PrimerError {
                    primerErr = error
                } else {
                    primerErr = PrimerError.generic(message: error!.localizedDescription, userInfo: nil, diagnosticsId: nil)
                }
                
                PrimerDelegateProxy.primerDidFailWithError(primerErr, data: nil) { errorDecision in
                    switch errorDecision.type {
                    case .fail(let message):
                        DispatchQueue.main.async {
                            Primer.shared.primerRootVC?.dismissOrShowResultScreen(type: .failure, withMessage: message)
                        }
                    }
                }
                return
            }
            
            self?.renderSelectedPaymentInstrument(insertAt: 1)
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
            savedPaymentMethodLabel.text = Strings.VaultPaymentMethodViewContent.savedPaymentMethod
            savedPaymentMethodLabel.adjustsFontSizeToFitWidth = true
            savedPaymentMethodLabel.minimumScaleFactor = 0.8
            savedPaymentMethodLabel.textColor = theme.text.subtitle.color
            savedPaymentMethodLabel.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)
            titleHorizontalStackView.addArrangedSubview(savedPaymentMethodLabel)
            
            let seeAllButton = UIButton()
            seeAllButton.translatesAutoresizingMaskIntoConstraints = false
            seeAllButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
            seeAllButton.setTitle(Strings.VaultPaymentMethodViewContent.seeAllButtonTitle, for: .normal)
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
            
            guard var amount = AppState.current.amount,
                  let currency = AppState.current.currency
            else {
                let err = PrimerError.invalidValue(key: "amount or currency", value: nil, userInfo: nil, diagnosticsId: nil)
                firstly {
                    PrimerDelegateProxy.raisePrimerDidFailWithError(err, data: nil)
                }
                .done { errMessage in
                    Primer.shared.primerRootVC?.dismissOrShowResultScreen(type: .failure, withMessage: errMessage)
                }
                .catch { _ in }
                return
            }
            
            
            if let surCharge = cardButtonViewModel.surCharge {                
                let surChargeLabel = UILabel()
                surChargeLabel.text = "+" + Int(surCharge).toCurrencyString(currency: currency)
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
                payButton = PrimerButton()
            }
            
            var title = Strings.PaymentButton.pay
            
            if amount != 0, let currency = AppState.current.currency {
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
        guard let selectedPaymentMethodType = selectedPaymentMethod.paymentMethodType else { return }
        guard let config = PrimerAPIConfiguration.paymentMethodConfigs?.filter({ $0.type == selectedPaymentMethodType }).first else {
            return
        }
        
        let viewEvent = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .click,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: config.type,
                    url: nil),
                extra: nil,
                objectType: .button,
                objectId: .pay,
                objectClass: "\(Self.self)",
                place: .universalCheckout))
        Analytics.Service.record(event: viewEvent)
        
        enableView(false)
        payButton.startAnimating()
        
        let checkoutWithVaultedPaymentMethodViewModel = CheckoutWithVaultedPaymentMethodViewModel(configuration: config, selectedPaymentMethodTokenData: selectedPaymentMethod)
        firstly {
            checkoutWithVaultedPaymentMethodViewModel.start()
        }
        .ensure {
            self.enableView(true)
        }
    }
    
}

extension PrimerUniversalCheckoutViewController {
    
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

extension PrimerUniversalCheckoutViewController: ReloadDelegate {
    func reload() {
        renderSelectedPaymentInstrument(insertAt: 1)
    }
}

#endif
