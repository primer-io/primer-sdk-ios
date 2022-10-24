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
    private let cardTokenizationModule: CardTokenizationModule
    
    init(navigationBarLogo: UIImage? = nil, cardTokenizationModule: CardTokenizationModule) {
        self.cardTokenizationModule = cardTokenizationModule
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
                    paymentMethodType: self.cardTokenizationModule.paymentMethodModule.paymentMethodConfiguration.type,
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
        _ = self.cardTokenizationModule.paymentMethodModule.userInterfaceModule.cardNumberField.becomeFirstResponder()
    }
    
    private func setupView() {
        view.backgroundColor = theme.view.backgroundColor
        verticalStackView.spacing = 6
        
        // Card and billing address fields
        renderInputView()
        
        // Separator view
        let separatorView = PrimerView()
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.heightAnchor.constraint(equalToConstant: 8).isActive = true
        verticalStackView.addArrangedSubview(separatorView)
        
        // Submit button
        renderSubmitButton()
    }
    
    private func renderInputView() {
        verticalStackView.addArrangedSubview(self.cardTokenizationModule.paymentMethodModule.userInterfaceModule.inputView!)
    }
    
    private func renderSubmitButton() {
        guard let submitButton = self.cardTokenizationModule.paymentMethodModule.userInterfaceModule.submitButton else { return }
        verticalStackView.addArrangedSubview(submitButton)
    }
}

#endif
