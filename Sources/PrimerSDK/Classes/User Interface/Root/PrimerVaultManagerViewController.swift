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
    private let paymentMethodModules = PrimerAPIConfigurationModule.paymentMethodModules
    
    override var title: String? {
        didSet {
            (parent as? PrimerContainerViewController)?.title = title
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let viewEvent = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .view,
                context: nil,
                extra: nil,
                objectType: .view,
                objectId: nil,
                objectClass: "\(Self.self)",
                place: .vaultManager))
        Analytics.Service.record(event: viewEvent)
        
        title = Strings.CardFormView.vaultNavBarTitle

        view.backgroundColor = theme.view.backgroundColor
        
        verticalStackView.spacing = 14.0

        if !paymentMethodModules.isEmpty {
            renderAvailablePaymentMethods()
        }
    }
    
    private func renderAvailablePaymentMethods() {
        PrimerFormViewController.renderPaymentMethods(paymentMethodModules, on: verticalStackView)
    }
}

#endif
