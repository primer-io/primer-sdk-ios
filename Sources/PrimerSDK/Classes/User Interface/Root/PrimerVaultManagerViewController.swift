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
        
        let checkoutViewModel: VaultCheckoutViewModelProtocol = DependencyContainer.resolve()
        let availablePaymentMethods = checkoutViewModel.availablePaymentOptions
        
        verticalStackView.spacing = 14.0
        
        if !availablePaymentMethods.isEmpty {
            let otherPaymentMethodsTitleLabel = UILabel()
            otherPaymentMethodsTitleLabel.text = NSLocalizedString("primer-vault-payment-method-available-payment-methods",
                                                                   tableName: nil,
                                                                   bundle: Bundle.primerResources,
                                                                   value: "Available payment methods",
                                                                   comment: "Available payment methods - Vault Checkout 'Available payment methods' Title").uppercased()
            
            otherPaymentMethodsTitleLabel.textColor = theme.colorTheme.secondaryText1
            otherPaymentMethodsTitleLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .regular)
            otherPaymentMethodsTitleLabel.textAlignment = .left
            verticalStackView.addArrangedSubview(otherPaymentMethodsTitleLabel)
            
            for paymentMethodTokenizationViewModel in paymentMethodConfigViewModels {
                paymentMethodTokenizationViewModel.didStartTokenization = {
                    Primer.shared.primerRootVC?.showLoadingScreenIfNeeded()
                }
                
                if var asyncPaymentMethodViewModel = paymentMethodTokenizationViewModel as? AsyncPaymentMethodTokenizationViewModelProtocol {
                    asyncPaymentMethodViewModel.willPresentPaymentMethod = {
                        Primer.shared.primerRootVC?.showLoadingScreenIfNeeded()
                    }
                    
                    asyncPaymentMethodViewModel.didPresentPaymentMethod = {
                        
                    }
                    
                    asyncPaymentMethodViewModel.willDismissPaymentMethod = {
                        Primer.shared.primerRootVC?.showLoadingScreenIfNeeded()
                    }
                }
                
                paymentMethodTokenizationViewModel.completion = { (tok, err) in
                    if let err = err {
                        Primer.shared.primerRootVC?.handle(error: err)
                    } else {
                        Primer.shared.primerRootVC?.handleSuccess()
                    }
                }
                
                verticalStackView.addArrangedSubview(paymentMethodTokenizationViewModel.paymentMethodButton)
            }
        }
    }
    
}
