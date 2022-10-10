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
    private var viewModel: PrimerTestPaymentMethodTokenizationViewModel!
    
    deinit {
        viewModel = nil
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    init(viewModel: PrimerTestPaymentMethodTokenizationViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.titleImage = viewModel.uiModule.invertedLogo
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
                    paymentMethodType: self.viewModel.config.type,
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
        view.backgroundColor = theme.view.backgroundColor
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: viewModel.viewHeight).isActive = true
        viewModel.tableView.isScrollEnabled = false
        verticalStackView.removeConstraints(verticalStackView.constraints)
        verticalStackView.pin(view: view, leading: 20, top: 0, trailing: -20, bottom: -20)
        verticalStackView.addArrangedSubview(viewModel.tableView)
        viewModel.tableView.translatesAutoresizingMaskIntoConstraints = false
    }
}

#endif
