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
    private let submitButton = PrimerButton()
    
    private let formPaymentMethodTokenizationViewModel: CardFormPaymentMethodTokenizationViewModel
    
    init(viewModel: CardFormPaymentMethodTokenizationViewModel) {
        self.formPaymentMethodTokenizationViewModel = viewModel
        super.init(nibName: nil, bundle: nil)
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
                    paymentMethodType: self.formPaymentMethodTokenizationViewModel.config.type.rawValue,
                    url: nil),
                extra: nil,
                objectType: .view,
                objectId: nil,
                objectClass: "\(Self.self)",
                place: .cardForm))
        Analytics.Service.record(event: viewEvent)
        
        setupView()
        formPaymentMethodTokenizationViewModel.completion = { (paymentMethodToken, err) in
            if let err = err {
                Primer.shared.primerRootVC?.handle(error: err)
            } else {
                Primer.shared.primerRootVC?.handleSuccess()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _ = formPaymentMethodTokenizationViewModel.cardNumberField.becomeFirstResponder()
    }
    
    private func setupView() {
        
        title = Content.PrimerCardFormView.title
        view.backgroundColor = theme.view.backgroundColor
        verticalStackView.spacing = 6
        renderCardAndBillingAddressFields()
        renderSaveCardView()
        
        // separator view
        let separatorView = PrimerView()
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.heightAnchor.constraint(equalToConstant: 8).isActive = true
        verticalStackView.addArrangedSubview(separatorView)
        
        // submit button
        renderSubmitButton()
    }
    
    private func renderCardAndBillingAddressFields() {
        verticalStackView.addArrangedSubview(formPaymentMethodTokenizationViewModel.formView)
    }

    private func renderSaveCardView() {
        
        if !Primer.shared.flow.internalSessionFlow.vaulted {
            let saveCardSwitchContainerStackView = UIStackView()
            saveCardSwitchContainerStackView.axis = .horizontal
            saveCardSwitchContainerStackView.alignment = .fill
            saveCardSwitchContainerStackView.spacing = 8.0
            
            let saveCardSwitch = UISwitch()
            saveCardSwitchContainerStackView.addArrangedSubview(saveCardSwitch)
            
            let saveCardLabel = UILabel()
            saveCardLabel.text = "Save this card"
            saveCardLabel.textColor = theme.text.body.color
            saveCardLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .regular)
            saveCardSwitchContainerStackView.addArrangedSubview(saveCardLabel)
            
            verticalStackView.addArrangedSubview(saveCardSwitchContainerStackView)
            saveCardSwitchContainerStackView.isHidden = true
        }
    }
    
    private func renderSubmitButton() {
        verticalStackView.addArrangedSubview(formPaymentMethodTokenizationViewModel.submitButton)
        submitButton.backgroundColor = theme.mainButton.color(for: .enabled)
    }
}

#endif
