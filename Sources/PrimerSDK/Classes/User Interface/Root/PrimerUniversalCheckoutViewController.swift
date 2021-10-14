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
    private var seeAllButton: UIButton!
    private var savedPaymentInstrumentStackView: UIStackView!
    private var payButton: PrimerOldButton!
    private var coveringView: PrimerView!
    private var selectedPaymentInstrument: PaymentMethodToken?
    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    private let paymentMethodConfigViewModels = PrimerConfiguration.paymentMethodConfigViewModels
    
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
        renderPayButton()
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
        if seeAllButton != nil {
            verticalStackView.removeArrangedSubview(seeAllButton)
            seeAllButton.removeFromSuperview()
            seeAllButton = nil
        }
        
        if savedCardView != nil {
            verticalStackView.removeArrangedSubview(savedCardView)
            savedCardView.removeFromSuperview()
            savedCardView = nil
        }
        
        if savedPaymentInstrumentStackView != nil {
            verticalStackView.removeArrangedSubview(savedPaymentInstrumentStackView)
            savedPaymentInstrumentStackView.removeFromSuperview()
            savedPaymentInstrumentStackView = nil
        }
        
        let checkoutViewModel: VaultCheckoutViewModelProtocol = DependencyContainer.resolve()
        
        self.selectedPaymentInstrument = nil
        if let selectedPaymentInstrument = checkoutViewModel.paymentMethods.first(where: { paymentInstrument in
            return paymentInstrument.token == checkoutViewModel.selectedPaymentMethodId
        }), let cardButtonViewModel = selectedPaymentInstrument.cardButtonViewModel {
            self.selectedPaymentInstrument = selectedPaymentInstrument
            
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
            savedPaymentInstrumentTitleLabel.textColor = theme.colorTheme.secondaryText1
            savedPaymentInstrumentTitleLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .regular)
            savedPaymentInstrumentTitleLabel.textAlignment = .left
            savedPaymentInstrumentStackView.addArrangedSubview(savedPaymentInstrumentTitleLabel)
            
            if savedCardView == nil {
                savedCardView = CardButton()
                savedPaymentInstrumentStackView.addArrangedSubview(savedCardView)
                savedCardView.translatesAutoresizingMaskIntoConstraints = false
                savedCardView.heightAnchor.constraint(equalToConstant: 64.0).isActive = true
                savedCardView.render(model: cardButtonViewModel, showIcon: false)
                
                let tapGesture = UITapGestureRecognizer()
                tapGesture.addTarget(self, action: #selector(togglePayButton))
                savedCardView.addGestureRecognizer(tapGesture)
            }
            
            if seeAllButton == nil {
                seeAllButton = UIButton()
                seeAllButton.translatesAutoresizingMaskIntoConstraints = false
                seeAllButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
                seeAllButton.setTitle("See all", for: .normal)
                seeAllButton.setTitleColor(theme.colorTheme.text3, for: .normal)
                seeAllButton.addTarget(self, action: #selector(seeAllButtonTapped), for: .touchUpInside)
                savedPaymentInstrumentStackView.addArrangedSubview(seeAllButton)
            }
            
            if let index = index {
                verticalStackView.insertArrangedSubview(savedPaymentInstrumentStackView, at: index)
            } else {
                verticalStackView.addArrangedSubview(savedPaymentInstrumentStackView)
            }
        } else {
            if savedCardView != nil {
                verticalStackView.removeArrangedSubview(savedCardView)
                savedCardView.removeFromSuperview()
                savedCardView = nil
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
        let otherPaymentMethodsTitleLabel = UILabel()
        otherPaymentMethodsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        otherPaymentMethodsTitleLabel.heightAnchor.constraint(equalToConstant: 16).isActive = true
        otherPaymentMethodsTitleLabel.text = NSLocalizedString("primer-vault-payment-method-available-payment-methods",
                                                               tableName: nil,
                                                               bundle: Bundle.primerResources,
                                                               value: "Available payment methods",
                                                               comment: "Available payment methods - Vault Checkout 'Available payment methods' Title").uppercased()
        otherPaymentMethodsTitleLabel.textColor = theme.colorTheme.secondaryText1
        otherPaymentMethodsTitleLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .regular)
        otherPaymentMethodsTitleLabel.textAlignment = .left
        
        verticalStackView.addArrangedSubview(otherPaymentMethodsTitleLabel)

        for paymentMethodTokenizationViewModel in paymentMethodConfigViewModels {
            paymentMethodTokenizationViewModel.didStartTokenization = {
                Primer.shared.primerRootVC?.showLoadingScreenIfNeeded()
            }
            
            if var asyncPaymentMethodViewModel = paymentMethodTokenizationViewModel as? AsyncPaymentMethodTokenizationViewModelProtocol {
                asyncPaymentMethodViewModel.willPresentPaymentMethod = {
                    Primer.shared.primerRootVC?.showLoadingScreenIfNeeded()
                }
                
                asyncPaymentMethodViewModel.didPresentPaymentMethod = {
                    
                }
                
                asyncPaymentMethodViewModel.willDismissPaymentMethod = {
                    Primer.shared.primerRootVC?.showLoadingScreenIfNeeded()
                }
            }
            
            paymentMethodTokenizationViewModel.completion = { (tok, err) in
                if let err = err {
                    Primer.shared.primerRootVC?.handle(error: err)
                } else {
                    Primer.shared.primerRootVC?.handleSuccess()
                }
            }
            
            verticalStackView.addArrangedSubview(paymentMethodTokenizationViewModel.paymentMethodButton)
        }
    }

    private func renderPayButton() {
        if coveringView == nil {
            coveringView = PrimerView()
        }
        
        coveringView.backgroundColor = theme.colorTheme.main1.withAlphaComponent(0.5)
        view.addSubview(coveringView)
        coveringView.translatesAutoresizingMaskIntoConstraints = false
        coveringView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        coveringView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        coveringView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        coveringView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
        
        if payButton == nil {
            payButton = PrimerOldButton()
        }
        
        payButton.layer.cornerRadius = 12
        payButton.setTitle(theme.content.vaultCheckout.payButtonText, for: .normal)
        payButton.setTitleColor(theme.colorTheme.text2, for: .normal)
        payButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        payButton.backgroundColor = theme.colorTheme.main2
        payButton.addTarget(self, action: #selector(payButtonTapped), for: .touchUpInside)
        let imageView = UIImageView(image: ImageName.lock.image)
        payButton.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.centerYAnchor.constraint(equalTo: payButton.centerYAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: payButton.trailingAnchor, constant: -16).isActive = true
        
        coveringView.addSubview(payButton)
        payButton.translatesAutoresizingMaskIntoConstraints = false
        payButton.leadingAnchor.constraint(equalTo: coveringView.leadingAnchor, constant: 20).isActive = true
        payButton.trailingAnchor.constraint(equalTo: coveringView.trailingAnchor, constant: -20).isActive = true
        payButton.bottomAnchor.constraint(equalTo: coveringView.bottomAnchor, constant: -10).isActive = true
        payButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        coveringView.isHidden = true
        
        let coveringViewTap = UITapGestureRecognizer()
        coveringViewTap.addTarget(self, action: #selector(togglePayButton))
        coveringView.addGestureRecognizer(coveringViewTap)
    }
    
    @objc
    func togglePayButton() {
        coveringView.isHidden = !coveringView.isHidden
        savedCardView.toggleBorder(isSelected: !coveringView.isHidden, isError: false)
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
    func payButtonTapped() {
        guard let paymentMethodToken = selectedPaymentInstrument else { return }
        
        payButton.showSpinner(true, color: theme.colorTheme.text2)
        Primer.shared.delegate?.onTokenizeSuccess?(paymentMethodToken, { err in
            DispatchQueue.main.async { [weak self] in
                self?.payButton.showSpinner(false)
                
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
