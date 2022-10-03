//
//  PrimerPaymentMethodManager.swift
//  PrimerSDK
//
//  Created by Evangelos on 26/9/22.
//

#if canImport(UIKit)

import Foundation

public enum PrimerPaymentMethodManagerCategory {
    case redirect, raw, cardComponents
}

protocol PrimerPaymentMethodManager {
    var paymentMethodType: String { get }
}

public class PrimerRedirectPaymentMethodManager: PrimerPaymentMethodManager {
    
    public let paymentMethodType: String
    private var paymentMethod: PrimerPaymentMethod?
    
    public init(paymentMethodType: String) {
        self.paymentMethodType = paymentMethodType
    }
    
    public func showPaymentMethod(intent: PrimerSessionIntent) throws {
        guard let clientToken = PrimerAPIConfigurationModule.clientToken,
              PrimerAPIConfigurationModule.apiConfiguration != nil
        else {
            let err = PrimerError.uninitializedSDKSession(userInfo: nil, diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard let paymentMethod = PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods?.first(where: { $0.type == self.paymentMethodType }) else {
            let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType, userInfo: nil, diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        self.paymentMethod = paymentMethod
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        settings.uiOptions.isInitScreenEnabled = false
        settings.uiOptions.isSuccessScreenEnabled = false
        settings.uiOptions.isErrorScreenEnabled = false
        
        PrimerInternal.shared.showPaymentMethod(self.paymentMethodType, withIntent: intent, andClientToken: clientToken)
    }
    
    public func cancel() {
        self.paymentMethod?.tokenizationViewModel?.cancel()
    }
}

#endif
