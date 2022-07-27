//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

#if canImport(UIKit)

import UIKit

protocol PaymentMethodsGroupViewDelegate {
    func paymentMethodsGroupView(_ paymentMethodsGroupView: PaymentMethodsGroupView, paymentMethodTapped paymentMethodTokenizationViewModels: PaymentMethodTokenizationViewModelProtocol)
}

class PaymentMethodsGroupView: PrimerView {
    
    internal private(set) var title: String?
    internal private(set) var paymentMethodTokenizationViewModels: [PaymentMethodTokenizationViewModelProtocol]!
    private var verticalStackView: UIStackView = UIStackView()
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

#endif
