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
                
        title = NSLocalizedString("primer-form-type-main-title-card-form",
                                  tableName: nil,
                                  bundle: Bundle.primerResources,
                                  value: "Enter your card details",
                                  comment: "Enter your card details - Form Type Main Title (Card)")

        view.backgroundColor = theme.colorTheme.main1
        
        verticalStackView.spacing = 6
        verticalStackView.addArrangedSubview(formPaymentMethodTokenizationViewModel.cardNumberContainerView)

        let horizontalStackView = UIStackView()
        horizontalStackView.axis = .horizontal
        horizontalStackView.alignment = .fill
        horizontalStackView.distribution = .fillEqually
        
        horizontalStackView.addArrangedSubview(formPaymentMethodTokenizationViewModel.expiryDateContainerView)
        
        horizontalStackView.addArrangedSubview(formPaymentMethodTokenizationViewModel.cvvContainerView)
        horizontalStackView.spacing = 16
        verticalStackView.addArrangedSubview(horizontalStackView)
        
        verticalStackView.addArrangedSubview(formPaymentMethodTokenizationViewModel.cardholderNameContainerView)
        
        if (formPaymentMethodTokenizationViewModel.requireZipCode) {
            verticalStackView.addArrangedSubview(formPaymentMethodTokenizationViewModel.zipCodeContainerView)
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
            saveCardLabel.textColor = theme.colorTheme.text1
            saveCardLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .regular)
            saveCardSwitchContainerStackView.addArrangedSubview(saveCardLabel)
            
            verticalStackView.addArrangedSubview(saveCardSwitchContainerStackView)
            saveCardSwitchContainerStackView.isHidden = true
        }
        
        let separatorView = UIView()
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.heightAnchor.constraint(equalToConstant: 8).isActive = true
        verticalStackView.addArrangedSubview(separatorView)
        
        verticalStackView.addArrangedSubview(formPaymentMethodTokenizationViewModel.submitButton)
    }
    
}

#endif
