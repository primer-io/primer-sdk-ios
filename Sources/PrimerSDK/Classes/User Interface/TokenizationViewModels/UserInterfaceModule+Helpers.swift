//
//  UserInterfaceModule+Helpers.swift
//  PrimerSDK
//
//  Created by Evangelos on 21/10/22.
//

#if canImport(UIKit)

import UIKit

extension UserInterfaceModule {
    
    internal var allVisibleBillingAddressFieldViews: [PrimerTextFieldView] {
        billingAddressFields.flatMap { $0.filter { $0.isFieldHidden == false } }.map { $0.fieldView }
    }
    
    internal var isShowingBillingAddressFieldsRequired: Bool {
        guard let billingAddressModule = PrimerAPIConfigurationModule.apiConfiguration?.checkoutModules?.filter({ $0.type == "BILLING_ADDRESS" }).first else { return false }
        return (billingAddressModule.options as? PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions)?.postalCode == true
    }
    
    internal var isRequiringCVVInput: Bool {
        guard let paymentMethodType = self.paymentMethodType else { return false }
        return paymentMethodType == .paymentCard
    }
    
    internal var billingAddressCheckoutModuleOptions: PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions? {
        return PrimerAPIConfigurationModule.apiConfiguration?.checkoutModules?.filter({ $0.type == "BILLING_ADDRESS" }).first?.options as? PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions
    }
    
    internal var isSubmitButtonAnimating: Bool {
        submitButton?.isAnimating == true
    }
    
    internal func makePrimerButtonWithTitleText(_ titleText: String, isEnabled: Bool) -> PrimerButton {
        let submitButton = PrimerButton()
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        submitButton.isAccessibilityElement = true
        submitButton.accessibilityIdentifier = "submit_btn"
        submitButton.isEnabled = isEnabled
        submitButton.setTitle(titleText, for: .normal)
        submitButton.backgroundColor = isEnabled ? theme.mainButton.color(for: .enabled) : theme.mainButton.color(for: .disabled)
        submitButton.setTitleColor(theme.mainButton.text.color, for: .normal)
        submitButton.layer.cornerRadius = 4
        submitButton.clipsToBounds = true
        submitButton.addTarget(self, action: #selector(submitButtonTapped(_:)), for: .touchUpInside)
        return submitButton
    }
    
    internal func makeIconImageView(withDimension dimension: CGFloat) -> UIImageView? {
        guard let squareLogo = self.icon else { return nil }
        let imgView = UIImageView()
        imgView.image = squareLogo
        imgView.contentMode = .scaleAspectFit
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.heightAnchor.constraint(equalToConstant: dimension).isActive = true
        imgView.widthAnchor.constraint(equalToConstant: dimension).isActive = true
        return imgView
    }
    
    internal func createInputTextFieldsStackViews(inputs: [Input], textFieldsDelegate: PrimerTextFieldViewDelegate) -> [UIStackView] {
        var stackViews: [UIStackView] = []
        
        for input in inputs {
            let stackView = UIStackView()
            stackView.spacing = 2
            stackView.axis = .horizontal
            stackView.alignment = .fill
            stackView.distribution = .fillProportionally
            
            let inputStackView = UIStackView()
            inputStackView.spacing = 2
            inputStackView.axis = .vertical
            inputStackView.alignment = .fill
            inputStackView.distribution = .fill
            
            let inputTextFieldView = PrimerGenericFieldView()
            inputTextFieldView.delegate = textFieldsDelegate
            inputTextFieldView.translatesAutoresizingMaskIntoConstraints = false
            inputTextFieldView.heightAnchor.constraint(equalToConstant: 35).isActive = true
            inputTextFieldView.textField.keyboardType = input.keyboardType ?? .default
            inputTextFieldView.allowedCharacterSet = input.allowedCharacterSet
            inputTextFieldView.maxCharactersAllowed = input.maxCharactersAllowed
            inputTextFieldView.isValid = input.isValid
            inputTextFieldView.shouldMaskText = false
            input.primerTextFieldView = inputTextFieldView
            
            let inputContainerView = PrimerCustomFieldView()
            inputContainerView.fieldView = inputTextFieldView
            inputContainerView.placeholderText = input.topPlaceholder
            inputContainerView.setup()
            inputContainerView.tintColor = .systemBlue
            inputStackView.addArrangedSubview(inputContainerView)
            
            if let descriptor = input.descriptor {
                let lbl = UILabel()
                lbl.font = UIFont.systemFont(ofSize: 12)
                lbl.translatesAutoresizingMaskIntoConstraints = false
                lbl.text = descriptor
                inputStackView.addArrangedSubview(lbl)
            }
            
            if self.paymentMethodModule.paymentMethodConfiguration.type == PrimerPaymentMethodType.adyenMBWay.rawValue {
                let phoneNumberLabelStackView = UIStackView()
                phoneNumberLabelStackView.spacing = 2
                phoneNumberLabelStackView.axis = .vertical
                phoneNumberLabelStackView.alignment = .fill
                phoneNumberLabelStackView.distribution = .fill
                phoneNumberLabelStackView.addArrangedSubview(self.paymentMethodModule.userInterfaceModule.mbwayTopLabelView)
                inputTextFieldView.font = UIFont.systemFont(ofSize: 17.0, weight: .regular)
                stackViews.insert(phoneNumberLabelStackView, at: 0)
                stackView.addArrangedSubview(self.paymentMethodModule.userInterfaceModule.prefixSelectorButton)
            }
            
            stackView.addArrangedSubview(inputStackView)
            stackViews.append(stackView)
        }
        
        return stackViews
    }
    
    internal func showTexfieldViewErrorIfNeeded(for primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {
        if isValid == false {
            // We know for sure that the text is not valid, even if the user hasn't finished typing.
            if primerTextFieldView is PrimerCardNumberFieldView, !primerTextFieldView.isEmpty {
                cardNumberContainerView.errorText = Strings.CardFormView.CardNumber.invalidErrorMessage
            } else if primerTextFieldView is PrimerExpiryDateFieldView, !primerTextFieldView.isEmpty {
                expiryDateContainerView.errorText = Strings.CardFormView.ExpiryDate.invalidErrorMessage
            } else if primerTextFieldView is PrimerCVVFieldView, !primerTextFieldView.isEmpty {
                cvvContainerView.errorText = Strings.CardFormView.CVV.invalidErrorMessage
            } else if primerTextFieldView is PrimerCardholderNameFieldView, !primerTextFieldView.isEmpty {
                cardholderNameContainerView?.errorText = Strings.CardFormView.Cardholder.invalidErrorMessage
            } else if primerTextFieldView is PrimerPostalCodeFieldView {
                postalCodeContainerView.errorText = primerTextFieldView.isEmpty ? Strings.CardFormView.PostalCode.isRequiredErrorMessage : Strings.CardFormView.PostalCode.invalidErrorMessage
            } else if primerTextFieldView is PrimerCountryFieldView {
                countryFieldContainerView.errorText = primerTextFieldView.isEmpty ? Strings.CardFormView.CountryCode.isRequiredErrorMessage : Strings.CardFormView.CountryCode.invalidErrorMessage
            } else if primerTextFieldView is PrimerFirstNameFieldView {
                firstNameContainerView.errorText = primerTextFieldView.isEmpty ? Strings.CardFormView.FirstName.isRequiredErrorMessage :  Strings.CardFormView.FirstName.invalidErrorMessage
            } else if primerTextFieldView is PrimerLastNameFieldView {
                lastNameContainerView.errorText = primerTextFieldView.isEmpty ? Strings.CardFormView.LastName.isRequiredErrorMessage :  Strings.CardFormView.LastName.invalidErrorMessage
            } else if primerTextFieldView is PrimerCityFieldView {
                cityContainerView.errorText = primerTextFieldView.isEmpty ? Strings.CardFormView.City.isRequiredErrorMessage :  Strings.CardFormView.City.invalidErrorMessage
            } else if primerTextFieldView is PrimerStateFieldView {
                stateContainerView.errorText = primerTextFieldView.isEmpty ? Strings.CardFormView.State.isRequiredErrorMessage :  Strings.CardFormView.State.invalidErrorMessage
            } else if primerTextFieldView is PrimerAddressLine1FieldView {
                addressLine1ContainerView.errorText = primerTextFieldView.isEmpty ? Strings.CardFormView.AddressLine1.isRequiredErrorMessage :  Strings.CardFormView.AddressLine1.invalidErrorMessage
            } else if primerTextFieldView is PrimerAddressLine2FieldView {
                addressLine2ContainerView.errorText = primerTextFieldView.isEmpty ? Strings.CardFormView.AddressLine2.isRequiredErrorMessage :  Strings.CardFormView.AddressLine2.invalidErrorMessage
            }
        } else {
            // We don't know for sure if the text is valid
            if primerTextFieldView is PrimerCardNumberFieldView {
                cardNumberContainerView.errorText = nil
            } else if primerTextFieldView is PrimerExpiryDateFieldView {
                expiryDateContainerView.errorText = nil
            } else if primerTextFieldView is PrimerCVVFieldView {
                cvvContainerView.errorText = nil
            } else if primerTextFieldView is PrimerCardholderNameFieldView {
                cardholderNameContainerView?.errorText = nil
            } else if primerTextFieldView is PrimerPostalCodeFieldView {
                postalCodeContainerView.errorText = nil
            } else if primerTextFieldView is PrimerCountryFieldView {
                countryFieldContainerView.errorText = nil
            } else if primerTextFieldView is PrimerFirstNameFieldView {
                firstNameContainerView.errorText = nil
            } else if primerTextFieldView is PrimerLastNameFieldView {
                lastNameContainerView.errorText = nil
            } else if primerTextFieldView is PrimerCityFieldView {
                cityContainerView.errorText = nil
            } else if primerTextFieldView is PrimerStateFieldView {
                stateContainerView.errorText = nil
            } else if primerTextFieldView is PrimerAddressLine1FieldView {
                addressLine1ContainerView.errorText = nil
            } else if primerTextFieldView is PrimerAddressLine2FieldView {
                addressLine2ContainerView.errorText = nil
            }
        }
    }
    
    internal func enableSubmitButtonIfNeeded() {
        switch self.paymentMethodModule.paymentMethodConfiguration.type {
        case PrimerPaymentMethodType.primerTestKlarna.rawValue,
            PrimerPaymentMethodType.primerTestPayPal.rawValue,
            PrimerPaymentMethodType.primerTestSofort.rawValue:
            if lastSelectedIndexPath != nil {
                self.submitButton?.isEnabled = true
                self.submitButton?.backgroundColor = theme.mainButton.color(for: .enabled)
            } else {
                self.submitButton?.isEnabled = false
                self.submitButton?.backgroundColor = theme.mainButton.color(for: .disabled)
            }
            
        default:
            var validations = [
                cardNumberField.isTextValid,
                expiryDateField.isTextValid,
            ]
            
            if isRequiringCVVInput {
                validations.append(cvvField.isTextValid)
            }
            
            if isShowingBillingAddressFieldsRequired {
                validations.append(contentsOf: allVisibleBillingAddressFieldViews.map { $0.isTextValid })
            }
            
            if cardholderNameField != nil { validations.append(cardholderNameField!.isTextValid) }
            
            if validations.allSatisfy({ $0 == true }) {
                self.submitButton?.isEnabled = true
                self.submitButton?.backgroundColor = theme.mainButton.color(for: .enabled)
            } else {
                self.submitButton?.isEnabled = false
                self.submitButton?.backgroundColor = theme.mainButton.color(for: .disabled)
            }
        }
    }
    
    internal func autofocusToNextFieldIfNeeded(for primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {
        if isValid == true {
            if primerTextFieldView is PrimerCardNumberFieldView {
                _ = expiryDateField.becomeFirstResponder()
            } else if primerTextFieldView is PrimerExpiryDateFieldView {
                _ = cvvField.becomeFirstResponder()
            } else if primerTextFieldView is PrimerCVVFieldView {
                _ = cardholderNameField?.becomeFirstResponder()
            }
        }
    }
    
    internal func updateButtonUI() {
        if let amount = AppState.current.amount, self.isSubmitButtonAnimating == false {
            self.configurePayButton(amount: amount)
        }
    }
    
    internal func configurePayButton(amount: Int) {
        DispatchQueue.main.async {
            guard PrimerInternal.shared.intent == .checkout, let currency = AppState.current.currency else {
                return
            }
            
            var title = Strings.PaymentButton.pay
            title += " \(amount.toCurrencyString(currency: currency))"
            self.submitButton?.setTitle(title, for: .normal)
        }
    }
    
    internal func enableSubmitButton(_ flag: Bool) {
        self.submitButton?.isEnabled = flag
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        self.submitButton?.backgroundColor = flag ? theme.mainButton.color(for: .enabled) : theme.mainButton.color(for: .disabled)
    }
    
    internal func makePaymentPendingInfoView(logo: UIImage? = nil, message: String) -> PrimerFormView {
        // The top logo
        
        let logoImageView = UIImageView(image: logo ?? self.paymentMethodModule.userInterfaceModule.logo)
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        logoImageView.clipsToBounds = true
        logoImageView.contentMode = .scaleAspectFit
        
        // Message string
        
        let completeYourPaymentLabel = UILabel()
        completeYourPaymentLabel.numberOfLines = 0
        completeYourPaymentLabel.textAlignment = .center
        completeYourPaymentLabel.text = message
        completeYourPaymentLabel.font = UIFont.systemFont(ofSize: PrimerDimensions.Font.label)
        completeYourPaymentLabel.textColor = theme.text.title.color
        
        let views = [[logoImageView],
                     [completeYourPaymentLabel]]
        
        return PrimerFormView(formViews: views)
    }
}

#endif
