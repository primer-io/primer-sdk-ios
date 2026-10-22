//
//  PrimerInputViewController.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit
@_spi(PrimerInternal) import PrimerUI

final class PrimerInputViewController: PrimerFormViewController {

    private let formPaymentMethodTokenizationViewModel: FormPaymentMethodTokenizationViewModel

    init(
        navigationBarLogo: UIImage?,
        formPaymentMethodTokenizationViewModel: FormPaymentMethodTokenizationViewModel,
        inputsDistribution: NSLayoutConstraint.Axis = .vertical
    ) {
        self.formPaymentMethodTokenizationViewModel = formPaymentMethodTokenizationViewModel
        super.init()
        titleImage = navigationBarLogo

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        verticalStackView.spacing = 16

        for inputStackView in formPaymentMethodTokenizationViewModel.inputTextFieldsStackViews {
            verticalStackView.addArrangedSubview(inputStackView)
        }

        guard let submitButton = formPaymentMethodTokenizationViewModel.uiModule.submitButton else { return }
        verticalStackView.addArrangedSubview(submitButton)
    }

}
