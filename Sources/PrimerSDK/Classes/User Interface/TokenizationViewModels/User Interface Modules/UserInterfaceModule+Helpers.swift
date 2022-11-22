//
//  UserInterfaceModule+Helpers.swift
//  PrimerSDK
//
//  Created by Evangelos on 21/10/22.
//

#if canImport(UIKit)

import UIKit

extension NewUserInterfaceModule {
    
    internal var isSubmitButtonAnimating: Bool {
        submitButton?.isAnimating == true
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
