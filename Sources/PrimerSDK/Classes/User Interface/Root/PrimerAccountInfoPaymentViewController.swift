//
//  PrimerAccountInfoPaymentViewController.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

final class PrimerAccountInfoPaymentViewController: PrimerFormViewController {

    let formPaymentMethodTokenizationViewModel: FormPaymentMethodTokenizationViewModel

    init(navigationBarLogo: UIImage?, formPaymentMethodTokenizationViewModel: FormPaymentMethodTokenizationViewModel) {
        self.formPaymentMethodTokenizationViewModel = formPaymentMethodTokenizationViewModel
        super.init()
        self.titleImage = navigationBarLogo
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        verticalStackView.spacing = 16

        if let infoView = self.formPaymentMethodTokenizationViewModel.infoView {
            verticalStackView.addArrangedSubview(infoView)
        }

        if let submitButton = self.formPaymentMethodTokenizationViewModel.uiModule.submitButton {
            verticalStackView.addArrangedSubview(submitButton)
        }
    }

}
