//
//  PrimerFormViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 27/7/21.
//

#if canImport(UIKit)

import UIKit

class PrimerFormViewController: PrimerViewController {

    internal var verticalStackView: UIStackView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(verticalStackView)

        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.alignment = .fill
        verticalStackView.axis = .vertical
        verticalStackView.distribution = .fill
        
        verticalStackView.pin(view: view, leading: 20, top: 20, trailing: -20, bottom: -20)
    }
    
    static func renderPaymentMethods(_ paymentMethodTokenizationViewModels: [PaymentMethodTokenizationViewModelProtocol], on stackView: UIStackView) {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        let otherPaymentMethodsTitleLabel = UILabel()
        otherPaymentMethodsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        otherPaymentMethodsTitleLabel.heightAnchor.constraint(equalToConstant: 16).isActive = true
        otherPaymentMethodsTitleLabel.text = NSLocalizedString("primer-vault-payment-method-available-payment-methods",
                                                               tableName: nil,
                                                               bundle: Bundle.primerResources,
                                                               value: "Available payment methods",
                                                               comment: "Available payment methods - Vault Checkout 'Available payment methods' Title").uppercased()
        otherPaymentMethodsTitleLabel.textColor = theme.text.subtitle.color
        otherPaymentMethodsTitleLabel.font = UIFont.systemFont(ofSize: 13.0, weight: .regular)
        otherPaymentMethodsTitleLabel.textAlignment = .left
        
        stackView.addArrangedSubview(otherPaymentMethodsTitleLabel)
        
        for paymentMethodTokenizationViewModel in paymentMethodTokenizationViewModels {
            PrimerFormViewController.handleCallbacks(for: paymentMethodTokenizationViewModel)
            stackView.addArrangedSubview(paymentMethodTokenizationViewModel.paymentMethodButton)
        }
    }
    
    static func handleCallbacks(for paymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModelProtocol) {
        paymentMethodTokenizationViewModel.didStartTokenization = {
            Primer.shared.primerRootVC?.showLoadingScreenIfNeeded()
        }
        
        if var asyncPaymentMethodViewModel = paymentMethodTokenizationViewModel as? ExternalPaymentMethodTokenizationViewModelProtocol {
            asyncPaymentMethodViewModel.willPresentExternalView = {
                Primer.shared.primerRootVC?.showLoadingScreenIfNeeded()
            }
            
            asyncPaymentMethodViewModel.didPresentExternalView = {
                
            }
            
            asyncPaymentMethodViewModel.willDismissExternalView = {
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
    }
    
}

#endif
