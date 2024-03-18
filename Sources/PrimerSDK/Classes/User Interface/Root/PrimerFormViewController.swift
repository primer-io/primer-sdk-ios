//
//  PrimerFormViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 27/7/21.
//

// swiftlint:disable function_body_length
// swiftlint:disable line_length

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

    static func renderPaymentMethods(_ paymentMethodTokenizationViewModels: [PaymentMethodTokenizationViewModelProtocol],
                                     on stackView: UIStackView) {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()

        let paymentMethodsContainerStack = UIStackView()
        paymentMethodsContainerStack.translatesAutoresizingMaskIntoConstraints = false
        paymentMethodsContainerStack.axis = .vertical
        paymentMethodsContainerStack.alignment = .fill
        paymentMethodsContainerStack.distribution = .fill
        paymentMethodsContainerStack.spacing = 5.0

        // No PMs to be rendered.
        if paymentMethodTokenizationViewModels.isEmpty { return }

        let otherPaymentMethodsTitleLabel = UILabel()
        otherPaymentMethodsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        otherPaymentMethodsTitleLabel.heightAnchor.constraint(equalToConstant: 16).isActive = true
        otherPaymentMethodsTitleLabel.text = Strings.VaultPaymentMethodViewContent.availablePaymentMethodsTitle.localizedUppercase

        otherPaymentMethodsTitleLabel.textColor = theme.text.subtitle.color
        otherPaymentMethodsTitleLabel.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)
        paymentMethodsContainerStack.addArrangedSubview(otherPaymentMethodsTitleLabel)

        if PrimerInternal.shared.intent == .vault {
            for viewModel in paymentMethodTokenizationViewModels {
                paymentMethodsContainerStack.addArrangedSubview(viewModel.uiModule.paymentMethodButton)
            }
            stackView.addArrangedSubview(paymentMethodsContainerStack)

        } else {
            // No surcharge fee
            let noAdditionalFeePaymentMethodsViewModels = paymentMethodTokenizationViewModels
                .filter({ $0.config.hasUnknownSurcharge == false && ($0.config.surcharge ?? 0) == 0 })
            // With surcharge fee
            let additionalFeePaymentMethodsViewModels = paymentMethodTokenizationViewModels
                .filter({ $0.config.hasUnknownSurcharge == false && ($0.config.surcharge ?? 0) != 0 })
            // Unknown surcharge fee
            let unknownFeePaymentMethodsViewModels = paymentMethodTokenizationViewModels
                .filter({ $0.config.hasUnknownSurcharge == true })

            if !noAdditionalFeePaymentMethodsViewModels.isEmpty,
               additionalFeePaymentMethodsViewModels.isEmpty,
               unknownFeePaymentMethodsViewModels.isEmpty {
                for viewModel in noAdditionalFeePaymentMethodsViewModels {
                    paymentMethodsContainerStack.addArrangedSubview(viewModel.uiModule.paymentMethodButton)
                }
                stackView.addArrangedSubview(paymentMethodsContainerStack)
                return
            }

            let paymentMethodsStack = UIStackView()
            paymentMethodsStack.translatesAutoresizingMaskIntoConstraints = false
            paymentMethodsStack.axis = .vertical
            paymentMethodsStack.alignment = .fill
            paymentMethodsStack.distribution = .fill
            paymentMethodsStack.spacing = 10.0

            if !noAdditionalFeePaymentMethodsViewModels.isEmpty {
                let noAdditionalFeesContainerView = PaymentMethodsGroupView(
                    title: Strings.CardFormView.noAdditionalFeesTitle,
                    paymentMethodTokenizationViewModels: noAdditionalFeePaymentMethodsViewModels)
                noAdditionalFeesContainerView.accessibilityIdentifier = "no_additional_fees_surcharge_group_view"
                noAdditionalFeesContainerView.titleLabel?.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)
                paymentMethodsStack.addArrangedSubview(noAdditionalFeesContainerView)
            }

            if !additionalFeePaymentMethodsViewModels.isEmpty {
                for additionalFeePaymentMethodsViewModel in additionalFeePaymentMethodsViewModels {
                    let title = additionalFeePaymentMethodsViewModel.uiModule.surchargeSectionText
                    let additionalFeesContainerView = PaymentMethodsGroupView(title: title,
                                                                              paymentMethodTokenizationViewModels: [additionalFeePaymentMethodsViewModel])
                    additionalFeesContainerView.accessibilityIdentifier = "\(additionalFeePaymentMethodsViewModel.config.type.lowercased())_surcharge_group_view"
                    additionalFeesContainerView.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
                    paymentMethodsStack.addArrangedSubview(additionalFeesContainerView)
                }
            }

            if !unknownFeePaymentMethodsViewModels.isEmpty {
                let unknownFeesContainerView = PaymentMethodsGroupView(
                    title: Strings.CardFormView.additionalFeesTitle,
                    paymentMethodTokenizationViewModels: unknownFeePaymentMethodsViewModels)
                unknownFeesContainerView.accessibilityIdentifier = "additional_fees_surcharge_group_view"

                unknownFeesContainerView.titleLabel?.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)
                paymentMethodsStack.addArrangedSubview(unknownFeesContainerView)
            }

            paymentMethodsContainerStack.addArrangedSubview(            paymentMethodsStack)
            stackView.addArrangedSubview(paymentMethodsContainerStack)
        }
    }
}
// swiftlint:enable function_body_length
// swiftlint:enable line_length
