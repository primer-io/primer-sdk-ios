//
//  PrimerCheckoutComponentsUIManager.swift
//  PrimerSDK
//
//  Created by Evangelos on 9/2/22.
//

import Foundation

public protocol PrimerHeadlessUniversalCheckoutInputData{}

extension PrimerHeadlessUniversalCheckout {
    struct IBANData: PrimerHeadlessUniversalCheckoutInputData {
        var iban: String
        var name: String
    }
    
    struct OTPData: PrimerHeadlessUniversalCheckoutInputData {
        var otp: String
    }
}

public protocol PrimerHeadlessUniversalCheckoutUIManager {
    init(paymentMethodType: PaymentMethodConfigType) throws
    func startTokenization(withData data: PrimerHeadlessUniversalCheckoutInputData?)
}

public protocol PrimerCardFormDelegate {
    func cardFormUIManager(_ cardFormUIManager: PrimerHeadlessUniversalCheckout.CardFormUIManager, isCardFormValid: Bool)
}

extension PrimerHeadlessUniversalCheckout {
    
    public class UIManager: PrimerHeadlessUniversalCheckoutUIManager {
        private(set) public var paymentMethodType: PaymentMethodConfigType
        private let appState: AppStateProtocol = DependencyContainer.resolve()
        
        required public init(paymentMethodType: PaymentMethodConfigType) throws {
            switch paymentMethodType {
            case .paymentCard:
                break
            default:
                break
            }
            
            do {
                try PrimerHeadlessUniversalCheckout.current.validateSession()
            } catch {
                ErrorHandler.handle(error: error)
                throw error
            }
            
            guard let availablePaymentMethodTypes = PrimerHeadlessUniversalCheckout.current.listAvailablePaymentMethodsTypes() else {
                let err = PrimerError.misconfiguredPaymentMethods(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                throw err
            }
            
            if availablePaymentMethodTypes.filter({ $0 == paymentMethodType }).isEmpty {
                let err = PrimerError.unableToPresentPaymentMethod(paymentMethodType: paymentMethodType, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                throw err
            }
            
            self.paymentMethodType = paymentMethodType
        }
        
        public func startTokenization(withData data: PrimerHeadlessUniversalCheckoutInputData? = nil) {
            guard let data = data else { return }
            
            if let ibanData = data as? IBANData {
                
            } else if let otpData = data as? OTPData {
                
            }
        }
    }
    
    public final class CardFormUIManager: UIManager, PrimerInputElementDelegate {
        
        private(set) public var requiredInputElementTypes: [PrimerInputElementType] = []
        public var inputElements: [PrimerInputElement] = [] {
            didSet {
                var tmpInputElementsDelegates: [(PrimerInputElement, PrimerInputElementDelegate)] = []
                inputElements.forEach { el in
                    tmpInputElementsDelegates.append(( el, el.inputElementDelegate ))
                }
                inputElements.forEach { el in
                    el.inputElementDelegate = self
                }
                originalInputElementsDelegates = tmpInputElementsDelegates
            }
        }
        private var originalInputElementsDelegates: [(PrimerInputElement, PrimerInputElementDelegate)] = []
        public var cardFormUIManagerDelegate: PrimerCardFormDelegate?
        private(set) public var isCardFormValid: Bool = false {
            didSet {
                cardFormUIManagerDelegate?.cardFormUIManager(self, isCardFormValid: isCardFormValid)
            }
        }
        
        public required init() throws {
            try super.init(paymentMethodType: .paymentCard)
            self.requiredInputElementTypes = PrimerHeadlessUniversalCheckout.current.listRequiredInputElementTypes(for: paymentMethodType) ?? []
        }
        
        required public init(paymentMethodType: PaymentMethodConfigType) throws {
            fatalError("init(paymentMethodType:) has not been implemented")
        }
        
        public override func startTokenization(withData data: PrimerHeadlessUniversalCheckoutInputData? = nil) {
            do {
                try PrimerHeadlessUniversalCheckout.current.validateSession()
            } catch {
                ErrorHandler.handle(error: error)
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutUniversalCheckoutDidFail(withError: error)
                return
            }
            
            PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutTokenizationStarted()

            firstly {
                self.validateInputData()
            }
            .then { () -> Promise<PaymentMethodTokenizationRequest> in
                return self.buildRequestBody()
            }
            .then { requestbody -> Promise<PaymentMethodToken> in
                return self.tokenize(request: requestbody)
            }
            .done { paymentMethodToken in
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutTokenizationSucceeded(paymentMethodToken: paymentMethodToken, resumeHandler: nil)
            }
            .catch { err in
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutUniversalCheckoutDidFail(withError: err)
            }
        }
        
        private func validateInputData() -> Promise<Void> {
            return Promise { seal in
                var errors: [PrimerError] = []
                for inputElementType in self.requiredInputElementTypes {
                    if self.inputElements.filter({ $0.type == inputElementType }).isEmpty {
                        let err = PrimerError.missingPrimerInputElement(inputElementType: inputElementType, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                        errors.append(err)
                    }
                }
                
                if !errors.isEmpty {
                    let err = PrimerError.underlyingErrors(errors: errors, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    seal.reject(err)
                    return
                }
                
                for inputElement in inputElements {
                    if !inputElement.isValid {
                        let err = PrimerError.invalidValue(key: "input-element", value: inputElement.type.rawValue, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                        errors.append(err)
                    }
                }
                
                if !errors.isEmpty {
                    let err = PrimerError.underlyingErrors(errors: errors, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    seal.reject(err)
                    return
                }
                
                seal.fulfill()
            }
        }
        
        private func buildRequestBody() -> Promise<PaymentMethodTokenizationRequest> {
            return Promise { seal in
                do {
                    switch self.paymentMethodType {
                    case .paymentCard:
                        guard let cardnumberField = inputElements.filter({ $0.type == .cardNumber }).first as? PrimerInputTextField,
                              let expiryDateField = inputElements.filter({ $0.type == .expiryDate }).first as? PrimerInputTextField,
                              let cvvField = inputElements.filter({ $0.type == .cvv }).first as? PrimerInputTextField
                        else {
                            let err = PrimerError.invalidValue(key: "input-element", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                            ErrorHandler.handle(error: err)
                            seal.reject(err)
                            return
                        }
                        
                        guard cardnumberField.isValid,
                              expiryDateField.isValid,
                              cvvField.isValid
                        else {
                            let err = PrimerError.invalidValue(key: "input-element", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                            ErrorHandler.handle(error: err)
                            seal.reject(err)
                            return
                        }
                        
                        guard let cardNumber = cardnumberField._text,
                              let expiryDate = expiryDateField._text,
                              let cvv = cvvField._text
                        else {
                            let err = PrimerError.invalidValue(key: "input-element", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                            ErrorHandler.handle(error: err)
                            seal.reject(err)
                            return
                        }
                        
                        let expiryArr = expiryDate.components(separatedBy: expiryDateField.type.delimiter!)
                        let expiryMonth = expiryArr[0]
                        let expiryYear = "20" + expiryArr[1]
                        
                        var cardholderName: String?
                        if let cardholderNameField = inputElements.filter({ $0.type == .cardholderName }).first as? PrimerInputTextField {
                            if !cardholderNameField.isValid {
                                let err = PrimerError.invalidValue(key: "cardholder-name", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                                ErrorHandler.handle(error: err)
                                seal.reject(err)
                                return
                            }
                            
                            cardholderName = cardholderNameField._text
                        }
                        
                        let paymentInstrument = PaymentInstrument(
                            number: PrimerInputElementType.cardNumber.clearFormatting(value: cardNumber) as! String,
                            cvv: cvv,
                            expirationMonth: expiryMonth,
                            expirationYear: expiryYear,
                            cardholderName: cardholderName,
                            paypalOrderId: nil,
                            paypalBillingAgreementId: nil,
                            shippingAddress: nil,
                            externalPayerInfo: nil,
                            paymentMethodConfigId: nil,
                            token: nil,
                            sourceConfig: nil,
                            gocardlessMandateId: nil,
                            klarnaAuthorizationToken: nil,
                            klarnaCustomerToken: nil,
                            sessionData: nil)
                        
                        let primerSettings: PrimerSettingsProtocol = DependencyContainer.resolve()
                        let customerId = primerSettings.customerId
                        let request = PaymentMethodTokenizationRequest(paymentInstrument: paymentInstrument, paymentFlow: nil, customerId: nil)
                        seal.fulfill(request)
                        
                    default:
                        fatalError()
                    }
                } catch {
                    seal.reject(error)
                }
            }
        }
        
        private func tokenize(request: PaymentMethodTokenizationRequest) -> Promise<PaymentMethodToken> {
            return Promise { seal in
                let apiClient: PrimerAPIClientProtocol = DependencyContainer.resolve()
                apiClient.tokenizePaymentMethod(clientToken: ClientTokenService.decodedClientToken!, paymentMethodTokenizationRequest: request) { result in
                    switch result {
                    case .success(let paymentMethodToken):
                        seal.fulfill(paymentMethodToken)

                    case .failure(let err):
                        let containerErr = PrimerError.underlyingErrors(errors: [err], userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                        ErrorHandler.handle(error: containerErr)
                        seal.reject(err)
                    }
                }
            }
        }
        
        private func inputElementShouldFocus(_ sender: PrimerInputElement) -> Bool {
            guard let senderTextField = sender as? PrimerInputTextField else { return true }
            guard let inputElementWithOriginalDelegate = originalInputElementsDelegates.filter({ ($0.0 as? PrimerInputTextField) == senderTextField }).first else { return true }
            
            if let shouldFocus = inputElementWithOriginalDelegate.1.inputElementShouldFocus?(sender) {
                return shouldFocus
            } else {
                return true
            }
        }
        
        private func inputElementDidFocus(_ sender: PrimerInputElement) {
            guard let senderTextField = sender as? PrimerInputTextField else { return }
            guard let inputElementWithOriginalDelegate = originalInputElementsDelegates.filter({ ($0.0 as? PrimerInputTextField) == senderTextField }).first else { return }
            inputElementWithOriginalDelegate.1.inputElementDidFocus?(sender)
        }
        
        private func inputElementShouldBlur(_ sender: PrimerInputElement) -> Bool {
            guard let senderTextField = sender as? PrimerInputTextField else { return true }
            guard let inputElementWithOriginalDelegate = originalInputElementsDelegates.filter({ ($0.0 as? PrimerInputTextField) == senderTextField }).first else { return true }
            
            if let shouldBlur = inputElementWithOriginalDelegate.1.inputElementShouldBlur?(sender) {
                return shouldBlur
            } else {
                return true
            }
        }
        
        private func inputElementDidBlur(_ sender: PrimerInputElement) {
            guard let senderTextField = sender as? PrimerInputTextField else { return }
            guard let inputElementWithOriginalDelegate = originalInputElementsDelegates.filter({ ($0.0 as? PrimerInputTextField) == senderTextField }).first else { return }
            inputElementWithOriginalDelegate.1.inputElementDidBlur?(sender)
        }
        
        private func inputElementValueDidChange(_ sender: PrimerInputElement) {
            guard let senderTextField = sender as? PrimerInputTextField else { return }
            guard let inputElementWithOriginalDelegate = originalInputElementsDelegates.filter({ ($0.0 as? PrimerInputTextField) == senderTextField }).first else { return }
            inputElementWithOriginalDelegate.1.inputElementValueDidChange?(sender)
        }
        
        private func inputElementDidDetectType(_ sender: PrimerInputElement, type: Any?) {
            guard let senderTextField = sender as? PrimerInputTextField else { return }
            guard let inputElementWithOriginalDelegate = originalInputElementsDelegates.filter({ ($0.0 as? PrimerInputTextField) == senderTextField }).first else { return }
            
            if let cvvTextField = self.inputElements.filter({ $0.type == .cvv }).first as? PrimerInputTextField {
                cvvTextField.detectedValueType = type
            }
            
            inputElementWithOriginalDelegate.1.inputElementDidDetectType?(sender, type: type)
        }
        
        private func inputElementValueIsValid(_ sender: PrimerInputElement, isValid: Bool) {
            guard let senderTextField = sender as? PrimerInputTextField else { return }
            guard let inputElementWithOriginalDelegate = originalInputElementsDelegates.filter({ ($0.0 as? PrimerInputTextField) == senderTextField }).first else { return }
            inputElementWithOriginalDelegate.1.inputElementValueIsValid?(sender, isValid: isValid)
            
            DispatchQueue.global(qos: .userInitiated).async {
                var tmpIsFormValid: Bool
                let inputElementsValidation = self.inputElements.compactMap({ $0.isValid })
                tmpIsFormValid = !inputElementsValidation.contains(false)
                
                if tmpIsFormValid != self.isCardFormValid {
                    self.isCardFormValid = tmpIsFormValid
                }
            }
        }
    }
    
}
