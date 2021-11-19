//
//  PrimerFormViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 27/7/21.
//

#if canImport(UIKit)

import UIKit

class PrimerFormViewController: PrimerViewController {

    internal var verticalStackView: UIStackView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(verticalStackView)

        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.alignment = .fill
        verticalStackView.axis = .vertical
        verticalStackView.distribution = .fill
        
        verticalStackView.pin(view: view, leading: 20, top: 20, trailing: -20, bottom: -20)
    }
    
    static func renderPaymentMethods(_ paymentMethodTokenizationViewModels: [PaymentMethodTokenizationViewModelProtocol], on stackView: UIStackView) {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        let availablePaymentMethodsContainerStackView = UIStackView()
        availablePaymentMethodsContainerStackView.axis = .vertical
        availablePaymentMethodsContainerStackView.alignment = .fill
        availablePaymentMethodsContainerStackView.distribution = .fill
        availablePaymentMethodsContainerStackView.spacing = 5.0
        
        if !paymentMethodTokenizationViewModels.isEmpty {
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
            
            if Primer.shared.flow.internalSessionFlow.vaulted {
                for viewModel in paymentMethodTokenizationViewModels {
                    availablePaymentMethodsContainerStackView.addArrangedSubview(viewModel.paymentMethodButton)
                }
                stackView.addArrangedSubview(availablePaymentMethodsContainerStackView)
                
            } else {
                // No surcharge fee
                
                let availablePaymentMethodsStackView = UIStackView()
                availablePaymentMethodsStackView.axis = .vertical
                availablePaymentMethodsStackView.alignment = .fill
                availablePaymentMethodsStackView.distribution = .fill
                availablePaymentMethodsStackView.spacing = 10.0

                let noAdditionalFeePaymentMethodsViewModels = paymentMethodTokenizationViewModels.filter({ $0.config.hasUnknownSurcharge == false && ($0.config.surcharge ?? 0) == 0 })
                if !noAdditionalFeePaymentMethodsViewModels.isEmpty {
                    let noAdditionalFeesContainerView = PaymentMethodsGroupView(title: "No additional fee", paymentMethodTokenizationViewModels: noAdditionalFeePaymentMethodsViewModels)
                    noAdditionalFeesContainerView.titleLabel?.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)
                    availablePaymentMethodsStackView.addArrangedSubview(noAdditionalFeesContainerView)
                }
                
                // With surcharge fee
                
                let additionalFeePaymentMethodsViewModels = paymentMethodTokenizationViewModels.filter({ $0.config.hasUnknownSurcharge == false && ($0.config.surcharge ?? 0) != 0 })
                if !additionalFeePaymentMethodsViewModels.isEmpty {
                    for additionalFeePaymentMethodsViewModel in additionalFeePaymentMethodsViewModels {
                        let title = additionalFeePaymentMethodsViewModel.surcharge
                        let additionalFeesContainerView = PaymentMethodsGroupView(title: title, paymentMethodTokenizationViewModels: [additionalFeePaymentMethodsViewModel])
                        additionalFeesContainerView.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
                        availablePaymentMethodsStackView.addArrangedSubview(additionalFeesContainerView)
                    }
                }
                
                // Unknown surcharge fee
                
                let unknownFeePaymentMethodsViewModels = paymentMethodTokenizationViewModels.filter({ $0.config.hasUnknownSurcharge == true })
                if !unknownFeePaymentMethodsViewModels.isEmpty {
                    let unknownFeesContainerView = PaymentMethodsGroupView(
                        title: NSLocalizedString("surcharge-additional-fee",
                                                 tableName: nil,
                                                 bundle: Bundle.primerResources,
                                                 value: "Additional fee may apply",
                                                 comment: "Additional fee may apply - Surcharge (Label)"),
                        paymentMethodTokenizationViewModels: unknownFeePaymentMethodsViewModels)
                    
                    unknownFeesContainerView.titleLabel?.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)
                    availablePaymentMethodsStackView.addArrangedSubview(unknownFeesContainerView)
                }

                availablePaymentMethodsContainerStackView.addArrangedSubview(availablePaymentMethodsStackView)
                stackView.addArrangedSubview(availablePaymentMethodsContainerStackView)
            }
            
        }
    }
    
    static func handleCallbacks(for paymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModelProtocol) {
        paymentMethodTokenizationViewModel.didStartTokenization = {
            Primer.shared.primerRootVC?.showLoadingScreenIfNeeded()
        }
        
        if var asyncPaymentMethodViewModel = paymentMethodTokenizationViewModel as? ExternalPaymentMethodTokenizationViewModelProtocol {
            asyncPaymentMethodViewModel.willPresentExternalView = {
                Primer.shared.primerRootVC?.showLoadingScreenIfNeeded()
            }
            
            asyncPaymentMethodViewModel.didPresentExternalView = {
                
            }
            
            asyncPaymentMethodViewModel.willDismissExternalView = {
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
    }
    
}

#endif
