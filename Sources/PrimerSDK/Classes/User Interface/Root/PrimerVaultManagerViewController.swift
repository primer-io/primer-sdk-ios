//
//  PrimerVaultManagerViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 2/8/21.
//

import UIKit

internal class PrimerVaultManagerViewController: PrimerFormViewController {
    
    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    private let paymentMethodConfigViewModels = PrimerConfiguration.paymentMethodConfigViewModels
    
    override var title: String? {
        didSet {
            (parent as? PrimerContainerViewController)?.title = title
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("primer-vault-nav-bar-title",
                                  tableName: nil,
                                  bundle: Bundle.primerResources,
                                  value: "Add payment method",
                                  comment: "Add payment method - Vault Navigation Bar Title")
        
        view.backgroundColor = theme.colorTheme.main1
        
        verticalStackView.spacing = 14.0
        renderAvailablePaymentMethods()
    }
    
    private func renderAvailablePaymentMethods() {
        PrimerFormViewController.renderPaymentMethods(paymentMethodConfigViewModels, on: verticalStackView, delegate: self)
    }
    
}

extension PrimerVaultManagerViewController: PaymentMethodsGroupViewDelegate {
    func paymentMethodsGroupView(_ paymentMethodsGroupView: PaymentMethodsGroupView, paymentMethodTapped paymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModelProtocol) {
        
    }
}
