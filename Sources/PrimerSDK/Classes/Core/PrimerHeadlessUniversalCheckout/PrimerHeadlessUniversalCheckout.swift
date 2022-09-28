//
//  PrimerHeadlessUniversalCheckout.swift
//  PrimerSDK
//
//  Created by Evangelos on 28/1/22.
//

#if canImport(UIKit)

import UIKit

public class PrimerHeadlessUniversalCheckout {
    
    public weak var delegate: PrimerCheckoutEventsDelegate?
    public weak var uiDelegate: PrimerUIEventsDelegate?
    private(set) public var clientToken: String?
    public static let current = PrimerHeadlessUniversalCheckout()
    private let unsupportedPaymentMethodTypes: [String] = [
        PrimerPaymentMethodType.adyenBlik.rawValue,
        PrimerPaymentMethodType.adyenDotPay.rawValue,
        PrimerPaymentMethodType.adyenIDeal.rawValue,
        PrimerPaymentMethodType.goCardless.rawValue,
        PrimerPaymentMethodType.primerTestKlarna.rawValue,
        PrimerPaymentMethodType.primerTestPayPal.rawValue,
        PrimerPaymentMethodType.primerTestSofort.rawValue,
        PrimerPaymentMethodType.xfersPayNow.rawValue,
    ]
    
    internal var apiConfigurationModule: PrimerAPIConfigurationModuleProtocol = PrimerAPIConfigurationModule()
    internal let sdkSessionId = UUID().uuidString
    internal private(set) var checkoutSessionId: String?
    internal private(set) var timingEventId: String?
    
    fileprivate init() {}
    
    public func start(
        withClientToken clientToken: String,
        settings: PrimerSettings? = nil,
        delegate: PrimerCheckoutEventsDelegate? = nil,
        uiDelegate: PrimerUIEventsDelegate? = nil,
        completion: @escaping (_ paymentMethods: [PrimerHeadlessUniversalCheckoutPaymentMethod]?, _ err: Error?) -> Void
    ) {
        PrimerInternal.shared.intent = .checkout
        
        if delegate != nil {
            PrimerHeadlessUniversalCheckout.current.delegate = delegate
        }
        
        if PrimerHeadlessUniversalCheckout.current.delegate == nil {
            print("WARNING!\nPrimerHeadlessUniversalCheckout delegate has not been set, and you won't be able to receive the Payment Method Token data to create a payment.")
        }
        
        PrimerInternal.shared.sdkIntegrationType = .headless
        PrimerInternal.shared.intent = .checkout
        
        self.checkoutSessionId = UUID().uuidString
        self.timingEventId = UUID().uuidString
        
        let sdkEvent = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: #function,
                params: [
                    "intent": PrimerInternal.shared.intent?.rawValue ?? "null"
                ]))
        
        let timingStartEvent = Analytics.Event(
            eventType: .timerEvent,
            properties: TimerEventProperties(
                momentType: .start,
                id: self.timingEventId))
        
        Analytics.Service.record(events: [sdkEvent, timingStartEvent])
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        settings.uiOptions.isInitScreenEnabled = false
        settings.uiOptions.isSuccessScreenEnabled = false
        settings.uiOptions.isErrorScreenEnabled = false
                
        firstly {
            self.apiConfigurationModule.setupSession(
                forClientToken: clientToken,
                requestDisplayMetadata: true,
                requestClientTokenValidation: false,
                requestVaultedPaymentMethods: false)
        }
        .done {
            let availablePaymentMethodsTypes = PrimerHeadlessUniversalCheckout.current.listAvailablePaymentMethodsTypes()
            if (availablePaymentMethodsTypes ?? []).isEmpty {
                let err = PrimerError.misconfiguredPaymentMethods(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                DispatchQueue.main.async {
                    completion(nil, err)
                }
            } else {
                DispatchQueue.main.async {
                    completion(PrimerHeadlessUniversalCheckoutPaymentMethod.availablePaymentMethods, nil)
                }
            }
        }
        .catch { err in
            DispatchQueue.main.async {
                completion(nil, err)
            }
        }
    }
    
    public func showPaymentMethod(_ paymentMethod: String) {
        DispatchQueue.main.async {
            let appState: AppStateProtocol = DependencyContainer.resolve()
            guard let clientToken = appState.clientToken else {
                print("WARNING!\nMake sure you have called 'start(withClientToken:settings:delegate:completion:' with a valid client token prior to showing a payment method.")
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidFail?(withError: err)
                return
            }
            
            if self.unsupportedPaymentMethodTypes.contains(paymentMethod) || paymentMethod == PrimerPaymentMethodType.paymentCard.rawValue {
                let err = PrimerError.unableToPresentPaymentMethod(paymentMethodType: paymentMethod, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidFail?(withError: err)
                return
            }
            
            PrimerSettings.current.uiOptions.isInitScreenEnabled = false
            PrimerSettings.current.uiOptions.isSuccessScreenEnabled = false
            PrimerSettings.current.uiOptions.isErrorScreenEnabled = false
            
            switch paymentMethod {
            case PrimerPaymentMethodType.goCardless.rawValue,
                PrimerPaymentMethodType.paymentCard.rawValue:
                let err = PrimerError.missingCustomUI(paymentMethod: paymentMethod, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidFail?(withError: err)
                return
                
            case PrimerPaymentMethodType.applePay.rawValue:
                if PrimerSettings.current.paymentMethodOptions.applePayOptions == nil {
                    let err = PrimerError.invalidValue(key: "settings.paymentMethodOptions.applePayOptions", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidFail?(withError: err)
                    return
                }
                
            case PrimerPaymentMethodType.payPal.rawValue:
                if PrimerSettings.current.paymentMethodOptions.urlScheme == nil {
                    let err = PrimerError.invalidUrlScheme(urlScheme: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidFail?(withError: err)
                    return
                }
                
            default:
                break
            }
            
            PrimerHeadlessUniversalCheckout.current.uiDelegate?.primerHeadlessUniversalCheckoutPreparationDidStart?(for: paymentMethod)
            PrimerInternal.shared.showPaymentMethod(paymentMethod, withIntent: .checkout, andClientToken: clientToken)
        }
    }
    
    // MARK: - HELPERS
    
    private func continueValidateSession() -> Promise<Void> {
        return Promise { seal in
            guard let clientToken = PrimerAPIConfigurationModule.clientToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)", "reason": "Client token is nil"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            guard let decodedJWTToken = clientToken.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)", "reason": "Client token cannot be decoded"], diagnosticsId: nil)
                seal.reject(err)
                return
            }
            
            do {
                try decodedJWTToken.validate()
            } catch {
                seal.reject(error)
            }
            
            guard let apiConfiguration = PrimerAPIConfigurationModule.apiConfiguration else {
                let err = PrimerError.missingPrimerConfiguration(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                seal.reject(err)
                return
            }
            
            guard let paymentMethods = apiConfiguration.paymentMethods, !paymentMethods.isEmpty else {
                let err = PrimerError.misconfiguredPaymentMethods(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                seal.reject(err)
                return
            }
            
            seal.fulfill()
        }
    }
    
    internal func validateSession() -> Promise<Void> {
        return Promise { seal in
            guard let clientToken = PrimerAPIConfigurationModule.clientToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)", "reason": "Client token is nil"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            guard let decodedJWTToken = clientToken.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)", "reason": "Client token cannot be decoded"], diagnosticsId: nil)
                seal.reject(err)
                return
            }
            
            do {
                try decodedJWTToken.validate()
            } catch {
                seal.reject(error)
            }
            
            guard let apiConfiguration = PrimerAPIConfigurationModule.apiConfiguration else {
                let err = PrimerError.missingPrimerConfiguration(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                seal.reject(err)
                return
            }
            
            guard let paymentMethods = apiConfiguration.paymentMethods, !paymentMethods.isEmpty else {
                let err = PrimerError.misconfiguredPaymentMethods(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                seal.reject(err)
                return
            }
            
            seal.fulfill()
        }
    }
    
    internal func listAvailablePaymentMethodsTypes() -> [String]? {
        var paymentMethods = PrimerAPIConfiguration.paymentMethodConfigs
        
#if !canImport(PrimerKlarnaSDK)
        if let klarnaIndex = paymentMethods?.firstIndex(where: { $0.type == PrimerPaymentMethodType.klarna.rawValue }) {

            paymentMethods?.remove(at: klarnaIndex)
            print("\nWARNING!\nKlarna configuration has been found but module 'PrimerKlarnaSDK' is missing. Add `PrimerKlarnaSDK' in your project by adding \"pod 'PrimerKlarnaSDK'\" in your podfile or by adding \"primer-klarna-sdk-ios\" in your Swift Package Manager, so you can perform payments with Klarna.\n\n")
        }
#endif
        
#if !canImport(PrimerIPay88SDK)
        if let iPay88ViewModelIndex = paymentMethods?.firstIndex(where: { $0.type == PrimerPaymentMethodType.iPay88Card.rawValue }) {
            paymentMethods?.remove(at: iPay88ViewModelIndex)
            print("\nWARNING!\niPay88 configuration has been found but module 'PrimerIPay88SDK' is missing. Add `PrimerIPay88SDK' in your project by adding \"pod 'PrimerIPay88SDK'\" in your podfile, so you can perform payments with iPay88.\n\n")
        }
#endif
        
        return paymentMethods?.compactMap({ $0.type }).filter({ !unsupportedPaymentMethodTypes.contains($0) })
    }
    
    public func listRequiredInputElementTypes(for paymentMethodType: String) -> [PrimerInputElementType]? {
        let sdkEvent = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: #function,
                params: [
                    "intent": PrimerInternal.shared.intent?.rawValue ?? "null"
                ]))
        
        Analytics.Service.record(events: [sdkEvent])
        
        switch paymentMethodType {
        case PrimerPaymentMethodType.paymentCard.rawValue:
            var requiredFields: [PrimerInputElementType] = [.cardNumber, .expiryDate, .cvv]
            let cardInfoOptions = PrimerAPIConfigurationModule.apiConfiguration?.checkoutModules?.filter({ $0.type == "CARD_INFORMATION" }).first?.options as? PrimerAPIConfiguration.CheckoutModule.CardInformationOptions
            if cardInfoOptions?.cardHolderName == false {
                return requiredFields
            }
            requiredFields.append(.cardholderName)
            return requiredFields
        case PrimerPaymentMethodType.adyenBancontactCard.rawValue:
            return [.cardNumber, .expiryDate, .cardholderName]
        case PrimerPaymentMethodType.xenditOvo.rawValue:
            return [.phoneNumber]
        case PrimerPaymentMethodType.xenditRetailOutlets.rawValue:
            return [.retailer]
        default:
            return []
        }
    }
}

extension PrimerHeadlessUniversalCheckout {
    
    internal class Delegate: NSObject, UITextFieldDelegate {
        
        private var inputElement: PrimerInputElement
        private weak var inputElementDelegate: PrimerInputElementDelegate?
        private var detectedType: Any?
        
        init(inputElement: PrimerInputElement, inputElementDelegate: PrimerInputElementDelegate) {
            self.inputElement = inputElement
            self.inputElementDelegate = inputElementDelegate
        }
        
        func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
            guard let inputElementShouldFocus = self.inputElementDelegate?.inputElementShouldFocus?(self.inputElement) else { return true }
            return inputElementShouldFocus
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            self.inputElementDelegate?.inputElementDidFocus?(self.inputElement)
        }
        
        func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
            guard let inputElementShouldBlur = self.inputElementDelegate?.inputElementShouldBlur?(self.inputElement) else { return true }
            return inputElementShouldBlur
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            self.inputElementDelegate?.inputElementDidBlur?(self.inputElement)
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            guard let primerCheckoutComponentsTextField = textField as? PrimerInputTextField else { return false }
            if !string.isEmpty {
                // Characters aren't in the allowed character set
                if let allowedCharacterSet = self.inputElement.type.allowedCharacterSet, string.rangeOfCharacter(from: allowedCharacterSet.inverted) != nil {
                    return false
                }
            }
            
            let currentText = primerCheckoutComponentsTextField._text ?? ""
            
            var newText = (currentText as NSString).replacingCharacters(in: range, with: string) as String
            if let deformattedText = self.inputElement.type.clearFormatting(value: newText) as? String {
                newText = deformattedText
            }
            
            if let maxAllowedLength = self.inputElement.type.maxAllowedLength {
                if newText.count > maxAllowedLength {
                    return false
                }
            }
            
            if self.inputElement.type == .cardNumber {
                if let cardNetwork = self.inputElement.type.detectType(for: newText) as? CardNetwork {
                    if self.detectedType == nil, cardNetwork != .unknown {
                        self.detectedType = cardNetwork
                        self.inputElementDelegate?.inputElementDidDetectType?(self.inputElement, type: self.detectedType)
                    } else if self.detectedType != nil, cardNetwork == .unknown {
                        self.detectedType = nil
                        self.inputElementDelegate?.inputElementDidDetectType?(self.inputElement, type: self.detectedType)
                    }
                } else {
                    if self.detectedType != nil {
                        self.detectedType = nil
                        self.inputElementDelegate?.inputElementDidDetectType?(self.inputElement, type: self.detectedType)
                    }
                }
            }
            
            if let cardNetwork = self.detectedType as? CardNetwork {
                if self.inputElement.type == .cardNumber,
                   let cardNetworkMaxAllowedLength = cardNetwork.validation?.lengths.max(),
                   newText.count > cardNetworkMaxAllowedLength {
                    return false
                }
                
            } else if let cardNetwork = primerCheckoutComponentsTextField.detectedValueType as? CardNetwork {
                if self.inputElement.type == .cvv {
                    if let cvvMaxAllowedLength = cardNetwork.validation?.code.length,
                       newText.count > cvvMaxAllowedLength {
                        return false
                    }
                }
            }
            
            let isValid = self.inputElement.type.validate(value: newText, detectedValueType: primerCheckoutComponentsTextField.detectedValueType)
            self.inputElementDelegate?.inputElementValueIsValid?(self.inputElement, isValid: isValid)
            
            let formattedText = self.inputElement.type.format(value: newText)
            textField.text = formattedText as? String
            
            return false
        }
    }
}

#endif
