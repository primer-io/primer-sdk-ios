//
//  CountrySelectorViewController.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import UIKit

final class CountrySelectorViewController: PrimerFormViewController {

    let theme: PrimerThemeProtocol = DependencyContainer.resolve()

    private var viewModel: SearchableItemsPaymentMethodTokenizationViewModelProtocol!
    private let countries = CountryCode.allCases
    private(set) var subtitle: String?

    deinit {
        viewModel.cancel()
        viewModel = nil
    }

    init(viewModel: SearchableItemsPaymentMethodTokenizationViewModelProtocol) {
        self.viewModel = viewModel
        super.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let context = AnalyticsContext(paymentMethodType: viewModel.config.type)
        postUIEvent(.view, context: context, type: .view, in: .countrySelectionList)

        view.backgroundColor = theme.view.backgroundColor
        view.translatesAutoresizingMaskIntoConstraints = false
        let constant = 120 + (CGFloat(countries.count) * viewModel.tableView.rowHeight)
        view.heightAnchor.constraint(equalToConstant: constant).isActive = true
        viewModel.tableView.isScrollEnabled = false

        verticalStackView.spacing = 5

        let theme: PrimerThemeProtocol = DependencyContainer.resolve()

        let countryTitleLabel = UILabel()
        countryTitleLabel.text = Strings.CountrySelector.selectCountryTitle
        countryTitleLabel.font = UIFont.systemFont(ofSize: 20)
        countryTitleLabel.textColor = theme.text.title.color
        verticalStackView.addArrangedSubview(countryTitleLabel)

        verticalStackView.addArrangedSubview(viewModel.searchableTextField)

        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 5).isActive = true
        verticalStackView.addArrangedSubview(separator)

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
