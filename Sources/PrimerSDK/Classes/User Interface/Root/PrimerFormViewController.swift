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
    
    static func renderPaymentMethods(_ orchestrators: [PrimerPaymentMethodOrchestrator], on stackView: UIStackView) {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        let availablePaymentMethodsContainerStackView = UIStackView()
        availablePaymentMethodsContainerStackView.translatesAutoresizingMaskIntoConstraints = false
        availablePaymentMethodsContainerStackView.axis = .vertical
        availablePaymentMethodsContainerStackView.alignment = .fill
        availablePaymentMethodsContainerStackView.distribution = .fill
        availablePaymentMethodsContainerStackView.spacing = 5.0
        
        // No PMs to be rendered.
        if orchestrators.isEmpty { return }
        
        let otherPaymentMethodsTitleLabel = UILabel()
        otherPaymentMethodsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        otherPaymentMethodsTitleLabel.heightAnchor.constraint(equalToConstant: 16).isActive = true
        otherPaymentMethodsTitleLabel.text = Strings.VaultPaymentMethodViewContent.availablePaymentMethodsTitle.localizedUppercase
        
        otherPaymentMethodsTitleLabel.textColor = theme.text.subtitle.color
        otherPaymentMethodsTitleLabel.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)
        availablePaymentMethodsContainerStackView.addArrangedSubview(otherPaymentMethodsTitleLabel)
        
        if PrimerInternal.shared.intent == .vault {
            for orchestrator in orchestrators {
                if let paymentMethodButton = orchestrator.uiModule.paymentMethodButton {
                    availablePaymentMethodsContainerStackView.addArrangedSubview(paymentMethodButton)
                }
            }
            stackView.addArrangedSubview(availablePaymentMethodsContainerStackView)
            
        } else {
            // No surcharge fee
            let noAdditionalFeeOrchestrators = orchestrators.filter({ $0.paymentMethodConfig.hasUnknownSurcharge == false && ($0.paymentMethodConfig.surcharge ?? 0) == 0 })
            // With surcharge fee
            let additionalFeeOrchestrators = orchestrators.filter({ $0.paymentMethodConfig.hasUnknownSurcharge == false && ($0.paymentMethodConfig.surcharge ?? 0) != 0 })
            // Unknown surcharge fee
            let unknownFeeOrchestrators = orchestrators.filter({ $0.paymentMethodConfig.hasUnknownSurcharge == true })
            
            if !noAdditionalFeeOrchestrators.isEmpty,
                additionalFeeOrchestrators.isEmpty,
                unknownFeeOrchestrators.isEmpty {
                for orchestrator in noAdditionalFeeOrchestrators {
                    if let paymentMethodButton = orchestrator.uiModule.paymentMethodButton {
                        availablePaymentMethodsContainerStackView.addArrangedSubview(paymentMethodButton)
                    }
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
            
            
            if !noAdditionalFeeOrchestrators.isEmpty {
                let noAdditionalFeesContainerView = PaymentMethodsGroupView(
                    title: Strings.CardFormView.noAdditionalFeesTitle,
                    uiModules: orchestrators.compactMap({ $0.uiModule }))
                noAdditionalFeesContainerView.accessibilityIdentifier = "no_additional_fees_surcharge_group_view"
                noAdditionalFeesContainerView.titleLabel?.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)
                availablePaymentMethodsStackView.addArrangedSubview(noAdditionalFeesContainerView)
            }
            
            if !additionalFeeOrchestrators.isEmpty {
                for additionalFeeOrchestrator in additionalFeeOrchestrators {
                    let title = additionalFeeOrchestrator.uiModule.surchargeSectionText
                    let additionalFeesContainerView = PaymentMethodsGroupView(title: title, uiModules: [additionalFeeOrchestrator.uiModule])
                    additionalFeesContainerView.accessibilityIdentifier = "\(additionalFeeOrchestrator.paymentMethodConfig.type.lowercased())_surcharge_group_view"
                    additionalFeesContainerView.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
                    availablePaymentMethodsStackView.addArrangedSubview(additionalFeesContainerView)
                }
            }
            
            if !unknownFeeOrchestrators.isEmpty {
                let unknownFeesContainerView = PaymentMethodsGroupView(
                    title: Strings.CardFormView.additionalFeesTitle,
                    uiModules: unknownFeeOrchestrators.compactMap({ $0.uiModule }))
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
