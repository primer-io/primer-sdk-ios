//
//  PaymentMethodNativeUIManager.swift
//  PrimerSDK
//
//  Created by Evangelos on 4/10/22.
//

#if canImport(UIKit)

import Foundation

extension PrimerHeadlessUniversalCheckout {
    
    public class NativeUIManager: PrimerPaymentMethodManager {
        
        public let paymentMethodType: String
        private var paymentMethod: PrimerPaymentMethod?
        
        required public init(paymentMethodType: String) throws {
            let sdkEvent = Analytics.Event(
                eventType: .sdkEvent,
                properties: SDKEventProperties(
                    name: #function,
                    params: [
                        "intent": PrimerInternal.shared.intent?.rawValue ?? "null",
                        "paymentMethodType": paymentMethodType
                    ]))
            
            Analytics.Service.record(events: [sdkEvent])
            
            self.paymentMethodType = paymentMethodType
            self.paymentMethod = try self.validatePaymentMethod(withType: paymentMethodType)
            
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            settings.uiOptions.isInitScreenEnabled = false
            settings.uiOptions.isSuccessScreenEnabled = false
            settings.uiOptions.isErrorScreenEnabled = false
        }
        
        @discardableResult
        private func validatePaymentMethod(withType paymentMethodType: String) throws -> PrimerPaymentMethod {
            guard PrimerAPIConfigurationModule.decodedJWTToken != nil,
                  PrimerAPIConfigurationModule.apiConfiguration != nil
            else {
                let err = PrimerError.uninitializedSDKSession(userInfo: nil, diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                throw err
            }
            
            guard let paymentMethod = PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods?.first(where: { $0.type == paymentMethodType }) else {
                let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType, userInfo: nil, diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                throw err
            }
            
            switch paymentMethodType {
            case PrimerPaymentMethodType.applePay.rawValue:
                if PrimerSettings.current.paymentMethodOptions.applePayOptions == nil {
                    let err = PrimerError.invalidValue(key: "settings.paymentMethodOptions.applePayOptions", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    throw err
                }
                
            case PrimerPaymentMethodType.payPal.rawValue:
                if PrimerSettings.current.paymentMethodOptions.urlScheme == nil {
                    let err = PrimerError.invalidUrlScheme(urlScheme: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    throw err
                }
                
            default:
                break
            }
            
            return paymentMethod
        }
        
        public func showPaymentMethod(intent: PrimerSessionIntent) throws {
            let sdkEvent = Analytics.Event(
                eventType: .sdkEvent,
                properties: SDKEventProperties(
                    name: #function,
                    params: [
                        "intent": PrimerInternal.shared.intent?.rawValue ?? "null",
                        "paymentMethodType": paymentMethodType
                    ]))
            
            Analytics.Service.record(events: [sdkEvent])
            
            do {
                try self.validatePaymentMethod(withType: self.paymentMethodType)
            } catch {
                throw error
            }

            PrimerHeadlessUniversalCheckout.current.uiDelegate?.primerHeadlessUniversalCheckoutUIDidStartPreparation?(for: self.paymentMethodType)
            PrimerInternal.shared.showPaymentMethod(self.paymentMethodType, withIntent: intent, andClientToken: PrimerAPIConfigurationModule.clientToken!)
        }
        
        private func cancel() {
            self.paymentMethod?.tokenizationViewModel?.cancel()
        }
    }
}



#endif

