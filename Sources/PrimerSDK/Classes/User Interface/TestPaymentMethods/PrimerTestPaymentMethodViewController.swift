//
//  PrimerTestPaymentMethodViewController.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 24/05/22.
//

#if canImport(UIKit)

import UIKit

class PrimerTestPaymentMethodViewController: PrimerFormViewController {
    
    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    private var paymentMethodModule: PaymentMethodModuleProtocol
    
    
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    init(paymentMethodModule: PaymentMethodModuleProtocol) {
        self.paymentMethodModule = paymentMethodModule
        super.init(nibName: nil, bundle: nil)
        self.titleImage = paymentMethodModule.userInterfaceModule.invertedLogo
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let viewEvent = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .view,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: self.paymentMethodModule.paymentMethodConfiguration.type,
                    url: nil),
                extra: nil,
                objectType: .view,
                objectId: nil,
                objectClass: "\(Self.self)",
                place: .bankSelectionList))
        Analytics.Service.record(event: viewEvent)

        setupView()
    }
}

extension PrimerTestPaymentMethodViewController {
    
    private func setupView() {
        guard let primerTestPaymentMethodModule = self.paymentMethodModule as? PrimerTestPaymentMethodTokenizationModule else {
            return
        }
        
        view.backgroundColor = theme.view.backgroundColor
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: primerTestPaymentMethodModule.viewHeight).isActive = true
        primerTestPaymentMethodModule.tableView.isScrollEnabled = false
        verticalStackView.removeConstraints(verticalStackView.constraints)
        verticalStackView.pin(view: view, leading: 20, top: 0, trailing: -20, bottom: -20)
        verticalStackView.addArrangedSubview(primerTestPaymentMethodModule.tableView)
        primerTestPaymentMethodModule.tableView.translatesAutoresizingMaskIntoConstraints = false
    }
}

#endif
