//
//  PrimerCardFormViewController.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import UIKit

/// Subclass of the PrimerFormViewController that uses the checkout components and the card components manager
final class PrimerCardFormViewController: PrimerFormViewController {

    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    private let formPaymentMethodTokenizationViewModel: CardFormPaymentMethodTokenizationViewModel

    init(navigationBarLogo: UIImage? = nil,
         viewModel: CardFormPaymentMethodTokenizationViewModel) {
        formPaymentMethodTokenizationViewModel = viewModel
        super.init()
        titleImage = navigationBarLogo
        if titleImage == nil {
            title = Strings.PrimerCardFormView.title
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let context = AnalyticsContext(paymentMethodType: formPaymentMethodTokenizationViewModel.config.type)
        postUIEvent(.view, context: context, type: .view, in: .cardForm)
        setupView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _ = formPaymentMethodTokenizationViewModel.cardNumberField.becomeFirstResponder()
    }

    private func setupView() {
        view.backgroundColor = theme.view.backgroundColor
        verticalStackView.spacing = 6

        // Card and billing address fields
        renderCardAndBillingAddressFields()

        // Separator view
        let separatorView = PrimerView()
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.heightAnchor.constraint(equalToConstant: 8).isActive = true
        verticalStackView.addArrangedSubview(separatorView)

        // Submit button
        renderSubmitButton()
    }

    private func renderCardAndBillingAddressFields() {
        verticalStackView.addArrangedSubview(formPaymentMethodTokenizationViewModel.formView)
    }

    private func renderSubmitButton() {
        guard let submitButton = formPaymentMethodTokenizationViewModel.uiModule.submitButton else { return }
        verticalStackView.addArrangedSubview(submitButton)
    }
}
