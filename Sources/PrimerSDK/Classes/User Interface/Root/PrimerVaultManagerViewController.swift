//
//  PrimerVaultManagerViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 2/8/21.
//

import UIKit

internal class PrimerVaultManagerViewController: PrimerFormViewController {
    
    let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    override var title: String? {
        didSet {
            (parent as? PrimerContainerViewController)?.title = title
        }
    }
    
    // swiftlint:disable function_body_length
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
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        let checkoutViewModel: VaultCheckoutViewModelProtocol = DependencyContainer.resolve()
        var availablePaymentMethods = checkoutViewModel.availablePaymentOptions.filter({ $0.type != .applePay })
        
        for (index, paymentMethod) in availablePaymentMethods.enumerated() {
            switch paymentMethod.type {
            case .klarna:
                availablePaymentMethods[index].surCharge = "+£5.36"
            case .paymentCard:
                availablePaymentMethods[index].surCharge = "Additional fee may apply"
            default:
                break
            }
            
        }
        
        let noAdditionalFeePaymentMethodsViewModels = availablePaymentMethods.filter({ $0.surCharge == nil })
        let additionalFeePaymentMethodsViewModels = availablePaymentMethods.filter({ $0.surCharge != nil })
        
        if !noAdditionalFeePaymentMethodsViewModels.isEmpty {
            let noAdditionalFeesContainerView = PaymentMethodsGroupView(frame: .zero, title: "No additional fee", paymentMethodsViewModels: noAdditionalFeePaymentMethodsViewModels)
            noAdditionalFeesContainerView.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .regular)
            noAdditionalFeesContainerView.delegate = self
            verticalStackView.addArrangedSubview(noAdditionalFeesContainerView)
        }
        
        if !additionalFeePaymentMethodsViewModels.isEmpty {
            for additionalFeePaymentMethodsViewModel in additionalFeePaymentMethodsViewModels {
                let title = additionalFeePaymentMethodsViewModel.surCharge
                let additionalFeesContainerView = PaymentMethodsGroupView(frame: .zero, title: title, paymentMethodsViewModels: [additionalFeePaymentMethodsViewModel])
                additionalFeesContainerView.titleLabel?.font = title == "Additional fee may apply" ? UIFont.systemFont(ofSize: 12, weight: .regular) : UIFont.systemFont(ofSize: 16, weight: .bold)
                additionalFeesContainerView.delegate = self
                verticalStackView.addArrangedSubview(additionalFeesContainerView)
            }
        }
    }
    
    @objc
    func klarnaButtonTapped() {
        let lvc = PrimerLoadingViewController(withHeight: 300)
        Primer.shared.primerRootVC?.show(viewController: lvc)
        Primer.shared.primerRootVC?.presentKlarna()
    }
    
    @objc
    func payPalButtonTapped() {
        if #available(iOS 11.0, *) {
            let lvc = PrimerLoadingViewController(withHeight: 300)
            Primer.shared.primerRootVC?.show(viewController: lvc)
            Primer.shared.primerRootVC?.presentPayPal()
        }
    }
    
    @objc
    func cardButtonTapped() {
        let cfvc = PrimerCardFormViewController(flow: .vault)
        Primer.shared.primerRootVC?.show(viewController: cfvc)
    }
    
}

extension PrimerVaultManagerViewController: PaymentMethodsGroupViewDelegate {
    func paymentMethodsGroupView(_ paymentMethodsGroupView: PaymentMethodsGroupView, paymentMethodTapped paymentMethod: PaymentMethodViewModel) {
        switch  paymentMethod.type {
        case .applePay:
            break
        case .apaya:
            break
        case .payPal:
            payPalButtonTapped()
        case .paymentCard:
            cardButtonTapped()
        case .googlePay:
            break
        case .goCardlessMandate:
            break
        case .klarna:
            klarnaButtonTapped()
        case .payNlIdeal:
            break
        case .unknown:
            break
        }
    }
}
