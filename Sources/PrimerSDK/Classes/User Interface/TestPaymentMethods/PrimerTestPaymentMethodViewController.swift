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
    private weak var paymentMethodConfiguration: PrimerPaymentMethod!
    private weak var userInterfaceModule: UserInterfaceModule!
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    init(paymentMethodConfiguration: PrimerPaymentMethod, userInterfaceModule: UserInterfaceModule) {
        super.init(nibName: nil, bundle: nil)
        self.paymentMethodConfiguration = paymentMethodConfiguration
        self.userInterfaceModule = userInterfaceModule
        self.titleImage = userInterfaceModule.navigationBarLogo
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
                    paymentMethodType: self.paymentMethodConfiguration.type,
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
        
        guard let inputAndResultInterfaceModule = userInterfaceModule as? InputAndResultUserInterfaceModule else {
            return
        }
        
        view.backgroundColor = theme.view.backgroundColor
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: inputAndResultInterfaceModule.viewHeight).isActive = true
        inputAndResultInterfaceModule.tableView.isScrollEnabled = false
        verticalStackView.removeConstraints(verticalStackView.constraints)
        verticalStackView.pin(view: view, leading: 20, top: 0, trailing: -20, bottom: -20)
        verticalStackView.addArrangedSubview(inputAndResultInterfaceModule.tableView)
        inputAndResultInterfaceModule.tableView.translatesAutoresizingMaskIntoConstraints = false
    }
}

#endif
