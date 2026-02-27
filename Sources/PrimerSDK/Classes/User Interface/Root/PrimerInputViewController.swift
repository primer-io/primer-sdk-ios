//
//  PrimerInputViewController.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerUI
import UIKit

final class PrimerInputViewController: PrimerFormViewController {

    private let formPaymentMethodTokenizationViewModel: FormPaymentMethodTokenizationViewModel

    init(
        navigationBarLogo: UIImage?,
        formPaymentMethodTokenizationViewModel: FormPaymentMethodTokenizationViewModel,
        inputsDistribution: NSLayoutConstraint.Axis = .vertical
    ) {
        self.formPaymentMethodTokenizationViewModel = formPaymentMethodTokenizationViewModel
        super.init()
        self.titleImage = navigationBarLogo

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        verticalStackView.spacing = 16

        for inputStackView in formPaymentMethodTokenizationViewModel.inputTextFieldsStackViews {
            verticalStackView.addArrangedSubview(inputStackView)
        }

        guard let submitButton = self.formPaymentMethodTokenizationViewModel.uiModule.submitButton else { return }
        verticalStackView.addArrangedSubview(submitButton)
    }

}
