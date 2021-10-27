//
//  PaymentMethodsGroupView.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 4/10/21.
//

import UIKit

protocol PaymentMethodsGroupViewDelegate {
    func paymentMethodsGroupView(_ paymentMethodsGroupView: PaymentMethodsGroupView, paymentMethodTapped paymentMethodTokenizationViewModels: PaymentMethodTokenizationViewModelProtocol)
}

class PaymentMethodsGroupView: PrimerView {
    
    internal private(set) var title: String?
    internal private(set) var paymentMethodTokenizationViewModels: [PaymentMethodTokenizationViewModelProtocol]!
    private var stackView: UIStackView = UIStackView()
    internal var delegate: PaymentMethodsGroupViewDelegate?
    internal var titleLabel: UILabel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        render()
    }
    
    convenience init(frame: CGRect = .zero, title: String?, paymentMethodTokenizationViewModels: [PaymentMethodTokenizationViewModelProtocol]) {
        self.init(frame: frame)
        self.title = title
        self.paymentMethodTokenizationViewModels = paymentMethodTokenizationViewModels
        render()
    }
    
    func render() {
        backgroundColor = .black.withAlphaComponent(0.05)
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 4.0
        clipsToBounds = true
        
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 7.0
        stackView.pin(view: self, leading: 10, top: 10, trailing: -10, bottom: -10)
        
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        if let title = title {
            titleLabel = UILabel()
            titleLabel!.text = title
            titleLabel!.textAlignment = .right
            titleLabel!.textColor = theme.colorTheme.text1
            stackView.addArrangedSubview(titleLabel!)
        }
        
        for viewModel in paymentMethodTokenizationViewModels {
            stackView.addArrangedSubview(viewModel.paymentMethodButton)
        }
    }
    
}
