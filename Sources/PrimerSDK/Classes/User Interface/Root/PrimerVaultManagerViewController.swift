//
//  PrimerVaultManagerViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 2/8/21.
//

#if canImport(UIKit)

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
        PrimerFormViewController.renderPaymentMethods(paymentMethodConfigViewModels, on: verticalStackView)
        
//        let checkoutViewModel: VaultCheckoutViewModelProtocol = DependencyContainer.resolve()
//        let availablePaymentMethods = checkoutViewModel.availablePaymentOptions.filter({ $0.type != .applePay })
//
//        let noAdditionalFeePaymentMethodsViewModels = availablePaymentMethods.filter({ $0.surCharge == nil })
//        let additionalFeePaymentMethodsViewModels = availablePaymentMethods.filter({ $0.surCharge != nil })
//
//<<<<<<< HEAD
//        if !noAdditionalFeePaymentMethodsViewModels.isEmpty {
//            let noAdditionalFeesContainerView = PaymentMethodsGroupView(title: "No additional fee", paymentMethodsViewModels: noAdditionalFeePaymentMethodsViewModels)
//            noAdditionalFeesContainerView.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .regular)
//            noAdditionalFeesContainerView.delegate = self
//            verticalStackView.addArrangedSubview(noAdditionalFeesContainerView)
//        }
//
//        if !additionalFeePaymentMethodsViewModels.isEmpty {
//            for additionalFeePaymentMethodsViewModel in additionalFeePaymentMethodsViewModels {
//                let title = additionalFeePaymentMethodsViewModel.surCharge
//                let additionalFeesContainerView = PaymentMethodsGroupView(title: title, paymentMethodsViewModels: [additionalFeePaymentMethodsViewModel])
//                additionalFeesContainerView.titleLabel?.font = (title == NSLocalizedString("surcharge-additional-fee",
//                                                                                           tableName: nil,
//                                                                                           bundle: Bundle.primerResources,
//                                                                                           value: "Additional fee may apply",
//                                                                                           comment: "Additional fee may apply - Surcharge (Label)"))
//                ? UIFont.systemFont(ofSize: 12, weight: .regular)
//                : UIFont.systemFont(ofSize: 16, weight: .bold)
//                additionalFeesContainerView.delegate = self
//                verticalStackView.addArrangedSubview(additionalFeesContainerView)
//            }
//        }
    }
    
//    @objc
//    func klarnaButtonTapped() {
//        let lvc = PrimerLoadingViewController(withHeight: 300)
//        Primer.shared.primerRootVC?.show(viewController: lvc)
//        Primer.shared.primerRootVC?.presentKlarna()
//    }
//
//    @objc
//    func payPalButtonTapped() {
//        if #available(iOS 11.0, *) {
//            let lvc = PrimerLoadingViewController(withHeight: 300)
//            Primer.shared.primerRootVC?.show(viewController: lvc)
//            Primer.shared.primerRootVC?.presentPayPal()
//=======
//        if !availablePaymentMethods.isEmpty {
//            renderAvailablePaymentMethods()
//>>>>>>> master
//        }
//    }
//
//    private func renderAvailablePaymentMethods() {
//        PrimerFormViewController.renderPaymentMethods(paymentMethodConfigViewModels, on: verticalStackView)
//    }
    
}

//<<<<<<< HEAD
//extension PrimerVaultManagerViewController: PaymentMethodsGroupViewDelegate {
//    func paymentMethodsGroupView(_ paymentMethodsGroupView: PaymentMethodsGroupView, paymentMethodTapped paymentMethod: PaymentMethodViewModel) {
//        switch  paymentMethod.type {
//        case .applePay:
//            break
//        case .apaya:
//            break
//        case .payPal:
//            payPalButtonTapped()
//        case .paymentCard:
//            cardButtonTapped()
//        case .googlePay:
//            break
//        case .goCardlessMandate:
//            break
//        case .klarna:
//            klarnaButtonTapped()
//        case .payNlIdeal:
//            break
//        case .unknown:
//            break
//        }
//    }
//}
//=======
#endif
//>>>>>>> master
