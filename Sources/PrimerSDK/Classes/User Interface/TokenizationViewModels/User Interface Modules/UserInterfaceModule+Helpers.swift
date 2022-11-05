//
//  UserInterfaceModule+Helpers.swift
//  PrimerSDK
//
//  Created by Evangelos on 21/10/22.
//

#if canImport(UIKit)

import UIKit

extension UserInterfaceModule {
    
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
                
    internal func enableSubmitButtonIfNeeded() {
//        switch self.paymentMethodModule.paymentMethodConfiguration.type {
//        case PrimerPaymentMethodType.primerTestKlarna.rawValue,
//            PrimerPaymentMethodType.primerTestPayPal.rawValue,
//            PrimerPaymentMethodType.primerTestSofort.rawValue:
//            if lastSelectedIndexPath != nil {
//                self.submitButton?.isEnabled = true
//                self.submitButton?.backgroundColor = theme.mainButton.color(for: .enabled)
//            } else {
//                self.submitButton?.isEnabled = false
//                self.submitButton?.backgroundColor = theme.mainButton.color(for: .disabled)
//            }
//
//        default:
//            var validations = [
//                cardNumberField.isTextValid,
//                expiryDateField.isTextValid,
//            ]
//
//            if isRequiringCVVInput {
//                validations.append(cvvField.isTextValid)
//            }
//
//            if isShowingBillingAddressFieldsRequired {
//                validations.append(contentsOf: allVisibleBillingAddressFieldViews.map { $0.isTextValid })
//            }
//
//            if cardholderNameField != nil { validations.append(cardholderNameField!.isTextValid) }
//
//            if validations.allSatisfy({ $0 == true }) {
//                self.submitButton?.isEnabled = true
//                self.submitButton?.backgroundColor = theme.mainButton.color(for: .enabled)
//            } else {
//                self.submitButton?.isEnabled = false
//                self.submitButton?.backgroundColor = theme.mainButton.color(for: .disabled)
//            }
//        }
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
    
    internal func makePaymentPendingInfoView(logo: UIImage, message: String) -> PrimerFormView {
        
        // The top logo
        
        let logoImageView = UIImageView(image: logo)
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
    
    @objc
    internal func copyToClipboardTapped(_ sender: UIButton) {
        UIPasteboard.general.string = PrimerAPIConfigurationModule.decodedJWTToken?.accountNumber
        
        log(logLevel: .debug, message: "📝📝📝📝 Copied: \(String(describing: UIPasteboard.general.string))")
        
        DispatchQueue.main.async {
            sender.isSelected = true
        }
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { timer in
            DispatchQueue.main.async {
                sender.isSelected = false
            }
            timer.invalidate()
        }
    }
}

#endif
