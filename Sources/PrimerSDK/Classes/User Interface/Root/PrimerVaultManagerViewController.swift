//
//  PrimerVaultManagerViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 2/8/21.
//

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
