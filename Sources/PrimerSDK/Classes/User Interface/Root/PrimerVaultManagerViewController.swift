//
//  PrimerVaultManagerViewController.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import UIKit

final class PrimerVaultManagerViewController: PrimerFormViewController {

    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    private let paymentMethodConfigViewModels = PrimerAPIConfiguration.paymentMethodConfigViewModels

    override var title: String? {
        didSet {
            (parent as? PrimerContainerViewController)?.title = title
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        postUIEvent(.view, type: .view, in: .vaultManager)
        title = Strings.CardFormView.vaultNavBarTitle

        view.backgroundColor = theme.view.backgroundColor

        verticalStackView.spacing = 14.0

        if !paymentMethodConfigViewModels.isEmpty {
            renderAvailablePaymentMethods()
        }
    }

    private func renderAvailablePaymentMethods() {
        PrimerFormViewController.renderPaymentMethods(paymentMethodConfigViewModels, on: verticalStackView)
    }
}
