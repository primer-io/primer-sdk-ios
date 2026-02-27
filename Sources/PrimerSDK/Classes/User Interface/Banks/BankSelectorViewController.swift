//
//  BankSelectorViewController.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import PrimerUI
import UIKit

final class BankSelectorViewController: PrimerFormViewController {

    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()

    private var viewModel: BankSelectorTokenizationViewModel!
    private(set) var subtitle: String?

    deinit {
        viewModel.cancel()
        viewModel = nil
    }

    init(viewModel: BankSelectorTokenizationViewModel) {
        self.viewModel = viewModel
        super.init()
        self.titleImage = viewModel.uiModule.invertedLogo
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let context = AnalyticsContext(paymentMethodType: viewModel.config.type)
        postUIEvent(.view, context: context, type: .view, in: .bankSelectionList)
        view.backgroundColor = theme.view.backgroundColor
        view.translatesAutoresizingMaskIntoConstraints = false
        let heightValue = 120 + (CGFloat(viewModel.banks.count)*viewModel.tableView.rowHeight)
        view.heightAnchor.constraint(equalToConstant: heightValue).isActive = true
        viewModel.tableView.isScrollEnabled = false

        verticalStackView.spacing = 5

        let theme: PrimerThemeProtocol = DependencyContainer.resolve()

        let bankTitleLabel = UILabel()
        bankTitleLabel.text = Strings.BankSelector.chooseBankTitle
        bankTitleLabel.font = UIFont.systemFont(ofSize: 20)
        bankTitleLabel.textColor = theme.text.title.color
        verticalStackView.addArrangedSubview(bankTitleLabel)
        bankTitleLabel.accessibilityIdentifier = AccessibilityIdentifier.BanksComponent.title.rawValue

        if let subtitle = subtitle {
            let bankSubtitleLabel = UILabel()
            bankSubtitleLabel.text = subtitle
            bankSubtitleLabel.font = UIFont.systemFont(ofSize: 14)
            bankSubtitleLabel.textColor = .black
            verticalStackView.addArrangedSubview(bankSubtitleLabel)
        }

        verticalStackView.addArrangedSubview(viewModel.searchBankTextField!)

        let separator2 = UIView()
        separator2.translatesAutoresizingMaskIntoConstraints = false
        separator2.heightAnchor.constraint(equalToConstant: 5).isActive = true
        verticalStackView.addArrangedSubview(separator2)

        let tableViewMockView = UIView()
        tableViewMockView.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.addArrangedSubview(tableViewMockView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.viewModel.tableView.superview == nil {
            let lastView = self.verticalStackView.arrangedSubviews.last!
            self.verticalStackView.removeArrangedSubview(lastView)
            self.verticalStackView.addArrangedSubview(self.viewModel.tableView)
            self.viewModel.tableView.translatesAutoresizingMaskIntoConstraints = false
        }
    }

}
