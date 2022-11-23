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
    
    internal var isPaymentMethodButtonAnimating: Bool {
        paymentMethodButton?.isAnimating == true
    }
}

extension UserInterfaceModule {
    
    func validateEnableSubmitButton() {
        if submitButtonValidations.allSatisfy({ $0 == true }) {
            self.submitButton?.isEnabled = true
            self.submitButton?.backgroundColor = theme.mainButton.color(for: .enabled)
        } else {
            self.submitButton?.isEnabled = false
            self.submitButton?.backgroundColor = theme.mainButton.color(for: .disabled)
        }
    }
}

extension UserInterfaceModule {

    internal func updateSubmitButton() {
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
}

#endif
