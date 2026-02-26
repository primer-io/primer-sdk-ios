//
//  PaymentMethodsGroupView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import UIKit

protocol PaymentMethodsGroupViewDelegate: AnyObject {
    func paymentMethodsGroupView(_ paymentMethodsGroupView: PaymentMethodsGroupView, paymentMethodTapped paymentMethodTokenizationViewModels: PaymentMethodTokenizationViewModelProtocol)
}

final class PaymentMethodsGroupView: PrimerView {

    private(set) var title: String?
    private(set) var paymentMethodTokenizationViewModels: [PaymentMethodTokenizationViewModelProtocol]!
    private var verticalStackView: UIStackView = UIStackView()
    var delegate: PaymentMethodsGroupViewDelegate?
    var titleLabel: UILabel?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        render()
    }

    convenience init(frame: CGRect = .zero,
                     title: String?,
                     paymentMethodTokenizationViewModels: [PaymentMethodTokenizationViewModelProtocol]) {
        self.init(frame: frame)
        self.title = title
        self.paymentMethodTokenizationViewModels = paymentMethodTokenizationViewModels
        render()
    }

    func render() {
        backgroundColor = UIColor.black.withAlphaComponent(0.05)
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 4.0
        clipsToBounds = true

        addSubview(verticalStackView)
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.axis = .vertical
        verticalStackView.alignment = .fill
        verticalStackView.distribution = .fill
        verticalStackView.spacing = 7.0
        verticalStackView.pin(view: self, leading: 10, top: 10, trailing: -10, bottom: -10)

        let theme: PrimerThemeProtocol = DependencyContainer.resolve()

        if let title = title {
            titleLabel = UILabel()
            titleLabel!.text = title

            // The text alignment here is set to .right by Primer Design
            // As a right-to-left reader
            // the default alignment for this label still results into the right hand side
            titleLabel!.textAlignment = .right

            titleLabel!.textColor = theme.text.title.color
            verticalStackView.addArrangedSubview(titleLabel!)
        }

        for viewModel in paymentMethodTokenizationViewModels {
            verticalStackView.addArrangedSubview(viewModel.uiModule.paymentMethodButton)
        }
    }

}
