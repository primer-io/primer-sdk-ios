//
//  PrimerCardFormViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 30/7/21.
//

#if canImport(UIKit)

import UIKit

/// Subclass of the PrimerFormViewController that uses the checkout components and the card components manager
class PrimerCardFormViewController: PrimerFormViewController {
    
    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()    
    private let uiModule: PrimerPaymentCardUIModule
    
    init(navigationBarLogo: UIImage? = nil, uiModule: PrimerPaymentCardUIModule) {
        self.uiModule = uiModule
        super.init(nibName: nil, bundle: nil)
        self.titleImage = navigationBarLogo
        if self.titleImage == nil {
            title = Strings.PrimerCardFormView.title
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let viewEvent = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .view,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: self.uiModule.paymentMethodOrchestrator.paymentMethodConfig.type,
                    url: nil),
                extra: nil,
                objectType: .view,
                objectId: nil,
                objectClass: "\(Self.self)",
                place: .cardForm))
        Analytics.Service.record(event: viewEvent)
        
        setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _ = uiModule.cardNumberField.becomeFirstResponder()
    }
    
    private func setupView() {
        view.backgroundColor = theme.view.backgroundColor
        verticalStackView.spacing = 6
        
        // Card and billing address fields
        renderCardAndBillingAddressFields()
        
        // Separator view
        let separatorView = PrimerView()
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.heightAnchor.constraint(equalToConstant: 8).isActive = true
        verticalStackView.addArrangedSubview(separatorView)
        
        // Submit button
        renderSubmitButton()
    }
    
    private func renderCardAndBillingAddressFields() {
        verticalStackView.addArrangedSubview(uiModule.formView)
    }
    
    private func renderSubmitButton() {
        guard let submitButton = uiModule.submitButton else { return }
        verticalStackView.addArrangedSubview(submitButton)
    }
}

#endif
