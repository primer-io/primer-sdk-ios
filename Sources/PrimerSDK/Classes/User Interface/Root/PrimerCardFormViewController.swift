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
    private let submitButton = PrimerOldButton()
    
    // todo: refactor to dynamic form builder
    private lazy var expiryAndCvvRow = row
    private lazy var zipCodeFieldRow = row
    
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
        
        formPaymentMethodTokenizationViewModel.onConfigurationFetched = onConfigurationFetched
        
        title = Content.PrimerCardFormView.title
        view.backgroundColor = theme.view.backgroundColor
        verticalStackView.spacing = 6
        verticalStackView.addArrangedSubview(formPaymentMethodTokenizationViewModel.cardNumberContainerView)
        
        configureExpiryAndCvvRow()
        
        if (formPaymentMethodTokenizationViewModel.requireZipCode) {
            configureZipCodeFieldRow()
        }
        
        // separator view
        let separatorView = PrimerView()
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.heightAnchor.constraint(equalToConstant: 8).isActive = true
        verticalStackView.addArrangedSubview(separatorView)
        
        // submit button
        verticalStackView.addArrangedSubview(formPaymentMethodTokenizationViewModel.submitButton)
        submitButton.backgroundColor = theme.mainButton.color(for: .enabled)
        
        _ = formPaymentMethodTokenizationViewModel.cardNumberField.becomeFirstResponder()
        
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
        formPaymentMethodTokenizationViewModel.cardNumberField.becomeFirstResponder()
    }

    private func configureExpiryAndCvvRow() {
        
        expiryAndCvvRow.addArrangedSubview(formPaymentMethodTokenizationViewModel.expiryDateContainerView)
        expiryAndCvvRow.addArrangedSubview(formPaymentMethodTokenizationViewModel.cvvContainerView)
        verticalStackView.addArrangedSubview(expiryAndCvvRow)
        
        if let cardholderNameContainerView = formPaymentMethodTokenizationViewModel.cardholderNameContainerView {
            verticalStackView.addArrangedSubview(cardholderNameContainerView)
        }
        
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
    
    private func configureZipCodeFieldRow() {
        zipCodeFieldRow.addArrangedSubview(formPaymentMethodTokenizationViewModel.zipCodeContainerView)
        zipCodeFieldRow.addArrangedSubview(PrimerView())
        verticalStackView.addArrangedSubview(zipCodeFieldRow)
    }
    
    private func onConfigurationFetched() {
        let zipView = formPaymentMethodTokenizationViewModel.zipCodeContainerView
        let isZipCodeViewHidden: Bool = !zipCodeFieldRow.arrangedSubviews.contains(zipView)
        let parentVC = parent as? PrimerContainerViewController
        
        let requireZipCode = formPaymentMethodTokenizationViewModel.requireZipCode
        
        verticalStackView.addArrangedSubview(formPaymentMethodTokenizationViewModel.submitButton)
        
        if (requireZipCode && isZipCodeViewHidden) {
            parentVC?.layoutContainerViewControllerIfNeeded { [weak self] in
                self?.zipCodeFieldRow.insertArrangedSubview(zipView, at: 0)
            }
        }
        
        if (!requireZipCode && !isZipCodeViewHidden) {
            parentVC?.layoutContainerViewControllerIfNeeded { [weak self] in
                self?.zipCodeFieldRow.removeArrangedSubview(zipView)
                zipView.removeFromSuperview()
            }
        }
        
       view.layoutIfNeeded()
    }
}

#endif
