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
    
    static func renderPaymentMethods(_ paymentMethodModules: [PaymentMethodModuleProtocol], on stackView: UIStackView) {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        let availablePaymentMethodsContainerStackView = UIStackView()
        availablePaymentMethodsContainerStackView.translatesAutoresizingMaskIntoConstraints = false
        availablePaymentMethodsContainerStackView.axis = .vertical
        availablePaymentMethodsContainerStackView.alignment = .fill
        availablePaymentMethodsContainerStackView.distribution = .fill
        availablePaymentMethodsContainerStackView.spacing = 5.0
        
        // No PMs to be rendered.
        if paymentMethodModules.isEmpty { return }
        
        let otherPaymentMethodsTitleLabel = UILabel()
        otherPaymentMethodsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        otherPaymentMethodsTitleLabel.heightAnchor.constraint(equalToConstant: 16).isActive = true
        otherPaymentMethodsTitleLabel.text = Strings.VaultPaymentMethodViewContent.mainTitleText.localizedUppercase
        
        otherPaymentMethodsTitleLabel.textColor = theme.text.subtitle.color
        otherPaymentMethodsTitleLabel.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)
        availablePaymentMethodsContainerStackView.addArrangedSubview(otherPaymentMethodsTitleLabel)
        
        if PrimerInternal.shared.intent == .vault {
            for paymentMethodModule in paymentMethodModules {
                availablePaymentMethodsContainerStackView.addArrangedSubview(paymentMethodModule.userInterfaceModule.paymentMethodButton)
            }
            stackView.addArrangedSubview(availablePaymentMethodsContainerStackView)
            
        } else {
            // No surcharge fee
            let noAdditionalFeePaymentMethodModules = paymentMethodModules.filter({ $0.paymentMethodConfiguration.hasUnknownSurcharge == false && ($0.paymentMethodConfiguration.surcharge ?? 0) == 0 })
            // With surcharge fee
            let additionalFeePaymentMethodModules = paymentMethodModules.filter({ $0.paymentMethodConfiguration.hasUnknownSurcharge == false && ($0.paymentMethodConfiguration.surcharge ?? 0) != 0 })
            // Unknown surcharge fee
            let unknownFeePaymentMethodsViewModels = paymentMethodModules.filter({ $0.paymentMethodConfiguration.hasUnknownSurcharge == true })
            
            if !noAdditionalFeePaymentMethodModules.isEmpty,
                additionalFeePaymentMethodModules.isEmpty,
                unknownFeePaymentMethodsViewModels.isEmpty {
                for paymentMethodModule in paymentMethodModules {
                    availablePaymentMethodsContainerStackView.addArrangedSubview(paymentMethodModule.userInterfaceModule.paymentMethodButton)
                }
                stackView.addArrangedSubview(availablePaymentMethodsContainerStackView)
                return
            }
            
            let availablePaymentMethodsStackView = UIStackView()
            availablePaymentMethodsStackView.translatesAutoresizingMaskIntoConstraints = false
            availablePaymentMethodsStackView.axis = .vertical
            availablePaymentMethodsStackView.alignment = .fill
            availablePaymentMethodsStackView.distribution = .fill
            availablePaymentMethodsStackView.spacing = 10.0
            
            
            if !noAdditionalFeePaymentMethodModules.isEmpty {
                let noAdditionalFeesContainerView = PaymentMethodsGroupView(
                    title: Strings.CardFormView.noAdditionalFeesTitle,
                    paymentMethodModules: noAdditionalFeePaymentMethodModules)
                noAdditionalFeesContainerView.accessibilityIdentifier = "no_additional_fees_surcharge_group_view"
                noAdditionalFeesContainerView.titleLabel?.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)
                availablePaymentMethodsStackView.addArrangedSubview(noAdditionalFeesContainerView)
            }
            
            if !additionalFeePaymentMethodModules.isEmpty {
                for additionalFeePaymentMethodModule in additionalFeePaymentMethodModules {
                    let title = additionalFeePaymentMethodModule.userInterfaceModule.surchargeSectionText
                    let additionalFeesContainerView = PaymentMethodsGroupView(title: title, paymentMethodModules: [additionalFeePaymentMethodModule])
                    additionalFeesContainerView.accessibilityIdentifier = "\(additionalFeePaymentMethodModule.paymentMethodConfiguration.type.lowercased())_surcharge_group_view"
                    additionalFeesContainerView.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
                    availablePaymentMethodsStackView.addArrangedSubview(additionalFeesContainerView)
                }
            }
            
            if !unknownFeePaymentMethodsViewModels.isEmpty {
                let unknownFeesContainerView = PaymentMethodsGroupView(
                    title: Strings.CardFormView.additionalFeesTitle,
                    paymentMethodModules: unknownFeePaymentMethodsViewModels)
                unknownFeesContainerView.accessibilityIdentifier = "additional_fees_surcharge_group_view"
                
                unknownFeesContainerView.titleLabel?.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)
                availablePaymentMethodsStackView.addArrangedSubview(unknownFeesContainerView)
            }
            
            availablePaymentMethodsContainerStackView.addArrangedSubview(availablePaymentMethodsStackView)
            stackView.addArrangedSubview(availablePaymentMethodsContainerStackView)
        }
    }
    
}

#endif
