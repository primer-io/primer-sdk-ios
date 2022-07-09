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
    
    private let cardholderNameContainerView = PrimerCustomFieldView()
    
    // todo: refactor to dynamic form builder
    private lazy var expiryAndCvvRow = row
    private lazy var postalCodeFieldRow = row
    
    private var row: UIStackView {
        let horizontalStackView = UIStackView()
        horizontalStackView.axis = .horizontal
        horizontalStackView.alignment = .fill
        horizontalStackView.distribution = .fillEqually
        horizontalStackView.spacing = 16
        return horizontalStackView
    }
    
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
        
        formPaymentMethodTokenizationViewModel.onConfigurationFetched = onConfigurationFetched
        
        title = Content.PrimerCardFormView.title
        view.backgroundColor = theme.view.backgroundColor
        verticalStackView.spacing = 6
        
        renderCardnumberRow()
        renderExpiryAndCvvRow()
        if (formPaymentMethodTokenizationViewModel.requirePostalCode) {
            renderPostalCodeFieldRow()
        }
        
        // separator view
        let separatorView = PrimerView()
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.heightAnchor.constraint(equalToConstant: 8).isActive = true
        verticalStackView.addArrangedSubview(separatorView)
        
        // submit button
        renderSubmitButton()
                
//        formPaymentMethodTokenizationViewModel.tokenizationCompletion = { (paymentMethodToken, err) in
//            if let err = err {
//                Primer.shared.primerRootVC?.handle(error: err)
//            } else {
//                Primer.shared.primerRootVC?.handleSuccess()
//            }
//        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _ = formPaymentMethodTokenizationViewModel.cardNumberField.becomeFirstResponder()
    }
    
    private func renderCardnumberRow() {
        verticalStackView.addArrangedSubview(formPaymentMethodTokenizationViewModel.cardNumberContainerView)
    }

    private func renderExpiryAndCvvRow() {
        expiryAndCvvRow.addArrangedSubview(formPaymentMethodTokenizationViewModel.expiryDateContainerView)
        expiryAndCvvRow.addArrangedSubview(formPaymentMethodTokenizationViewModel.cvvContainerView)
        verticalStackView.addArrangedSubview(expiryAndCvvRow)
        
        if let cardholderNameContainerView = formPaymentMethodTokenizationViewModel.cardholderNameContainerView {
            verticalStackView.addArrangedSubview(cardholderNameContainerView)
        }
        
        if Primer.shared.intent == .checkout {
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
    
    private func renderPostalCodeFieldRow() {
        postalCodeFieldRow.addArrangedSubview(formPaymentMethodTokenizationViewModel.postalCodeContainerView)
        postalCodeFieldRow.addArrangedSubview(PrimerView())
        verticalStackView.addArrangedSubview(postalCodeFieldRow)
    }
    
    private func renderSubmitButton() {
        guard let submitButton = self.formPaymentMethodTokenizationViewModel.uiModule.submitButton else { return }
        verticalStackView.addArrangedSubview(submitButton)
        submitButton.backgroundColor = theme.mainButton.color(for: .enabled)
    }
    
    private func onConfigurationFetched() {
        let postalCodeView = formPaymentMethodTokenizationViewModel.postalCodeContainerView
        let isPostalCodeViewHidden: Bool = !postalCodeFieldRow.arrangedSubviews.contains(postalCodeView)
        let parentVC = parent as? PrimerContainerViewController
        
        let requirePostalCode = formPaymentMethodTokenizationViewModel.requirePostalCode
        
        if (requirePostalCode && isPostalCodeViewHidden) {
            parentVC?.layoutContainerViewControllerIfNeeded { [weak self] in
                self?.postalCodeFieldRow.insertArrangedSubview(postalCodeView, at: 0)
            }
        }
        
        if (!requirePostalCode && !isPostalCodeViewHidden) {
            parentVC?.layoutContainerViewControllerIfNeeded { [weak self] in
                self?.postalCodeFieldRow.removeArrangedSubview(postalCodeView)
                postalCodeView.removeFromSuperview()
            }
        }
        
       view.layoutIfNeeded()
    }
}

#endif
