//
//  PrimerFormViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 27/7/21.
//

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
        
        verticalStackView.pin(view: view, leading: 20, top: 20, trailing: -20, bottom: -20)
    }
    
    static func renderPaymentMethods(_ paymentMethodTokenizationViewModels: [PaymentMethodTokenizationViewModelProtocol], on stackView: UIStackView, delegate: PaymentMethodsGroupViewDelegate) {
        if !paymentMethodTokenizationViewModels.isEmpty {
            let theme: PrimerThemeProtocol = DependencyContainer.resolve()
            
            let availablePaymentMethodsContainerStackView = UIStackView()
            availablePaymentMethodsContainerStackView.axis = .vertical
            availablePaymentMethodsContainerStackView.alignment = .fill
            availablePaymentMethodsContainerStackView.distribution = .fill
            availablePaymentMethodsContainerStackView.spacing = 5.0
            
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
            
            let noAdditionalFeeTokenizationViewModels = paymentMethodTokenizationViewModels.filter({ $0.config.surcharge == nil })
            
            if !noAdditionalFeeTokenizationViewModels.isEmpty {
                let noAdditionalFeesContainerView = PaymentMethodsGroupView(title: "No additional fee", paymentMethodTokenizationViewModels: noAdditionalFeeTokenizationViewModels, delegate: delegate)
                noAdditionalFeesContainerView.titleLabel?.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)
                noAdditionalFeesContainerView.delegate = delegate
                availablePaymentMethodsStackView.addArrangedSubview(noAdditionalFeesContainerView)
            }
            
            let additionalFeeTokenizationViewModels = paymentMethodTokenizationViewModels.filter({ $0.config.surcharge != nil })
            
            if !additionalFeeTokenizationViewModels.isEmpty {
                for additionalFeeTokenizationViewModel in additionalFeeTokenizationViewModels {
                    let title = additionalFeeTokenizationViewModel.surCharge
                    let additionalFeesContainerView = PaymentMethodsGroupView(title: title, paymentMethodTokenizationViewModels: [additionalFeeTokenizationViewModel], delegate: delegate)
                    additionalFeesContainerView.titleLabel?.font = (title == NSLocalizedString("surcharge-additional-fee",
                                                                                               tableName: nil,
                                                                                               bundle: Bundle.primerResources,
                                                                                               value: "Additional fee may apply",
                                                                                               comment: "Additional fee may apply - Surcharge (Label)"))
                    ? UIFont.systemFont(ofSize: 12.0, weight: .regular)
                    : UIFont.systemFont(ofSize: 16.0, weight: .bold)
                    additionalFeesContainerView.delegate = delegate
                    availablePaymentMethodsStackView.addArrangedSubview(additionalFeesContainerView)
                }
            }
            
            availablePaymentMethodsContainerStackView.addArrangedSubview(availablePaymentMethodsStackView)
            
            stackView.addArrangedSubview(availablePaymentMethodsContainerStackView)
        }
    }
    
}
