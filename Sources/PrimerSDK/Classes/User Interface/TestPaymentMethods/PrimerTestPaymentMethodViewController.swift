//
//  PrimerTestPaymentMethodViewController.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import UIKit

final class PrimerTestPaymentMethodViewController: PrimerFormViewController {

    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    private var viewModel: PrimerTestPaymentMethodTokenizationViewModel!

    deinit {
        viewModel.cancel()
        viewModel = nil
    }

    init(viewModel: PrimerTestPaymentMethodTokenizationViewModel) {
        self.viewModel = viewModel
        super.init()
        self.titleImage = viewModel.uiModule.invertedLogo
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let context = AnalyticsContext(paymentMethodType: viewModel.config.type)
        postUIEvent(.view, context: context, type: .view, in: .bankSelectionList)
        setupView()
    }
}

extension PrimerTestPaymentMethodViewController {

    private func setupView() {
        view.backgroundColor = theme.view.backgroundColor
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: viewModel.viewHeight).isActive = true
        viewModel.tableView.isScrollEnabled = false
        verticalStackView.removeConstraints(verticalStackView.constraints)
        verticalStackView.pin(view: view, leading: 20, top: 0, trailing: -20, bottom: -20)
        verticalStackView.addArrangedSubview(viewModel.tableView)
        viewModel.tableView.translatesAutoresizingMaskIntoConstraints = false
    }
}
