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
    init(paymentMethodType: PrimerPaymentMethodType) throws
    func tokenize(withData data: PrimerHeadlessUniversalCheckoutInputData?)
}

public protocol PrimerCardFormDelegate: AnyObject  {
    func cardFormUIManager(_ cardFormUIManager: PrimerHeadlessUniversalCheckout.CardFormUIManager, isCardFormValid: Bool)
}

extension PrimerHeadlessUniversalCheckout {
    
    public class UIManager: PrimerHeadlessUniversalCheckoutUIManager {
        
        private(set) public var paymentMethodType: PrimerPaymentMethodType
        private let appState: AppStateProtocol = AppState.current
        
        required public init(paymentMethodType: PrimerPaymentMethodType) throws {
            
            guard let availablePaymentMethodTypes = PrimerHeadlessUniversalCheckout.current.listAvailablePaymentMethodsTypes() else {
                let err = PrimerError.misconfiguredPaymentMethods(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                throw err
            }
            
            if availablePaymentMethodTypes.filter({ $0 == paymentMethodType }).isEmpty {
                let err = PrimerError.unableToPresentPaymentMethod(paymentMethodType: paymentMethodType, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                throw err
            }
            
            self.paymentMethodType = paymentMethodType
        }
        
        public func tokenize(withData data: PrimerHeadlessUniversalCheckoutInputData? = nil) {
            
            // TODO: Implement data handling
            
            //            guard let data = data else { return }
            //
            //            if let ibanData = data as? IBANData {
            //
            //            } else if let otpData = data as? OTPData {
            //
            //            }
            //
        }
    }
    
    public final class CardFormUIManager: UIManager, PrimerInputElementDelegate {
        
        private(set) public var requiredInputElementTypes: [PrimerInputElementType] = []
        public var inputElements: [PrimerInputElement] = [] {
            didSet {
                var tmpInputElementsContainers: [Weak<PrimerInputElementDelegateContainer>] = []
                inputElements.forEach { el in
                    if let _ = el.inputElementDelegate {
                        tmpInputElementsContainers.append(Weak(value: PrimerInputElementDelegateContainer(element: el, delegate: el.inputElementDelegate)))
                    }
                }
                inputElements.forEach { el in
                    el.inputElementDelegate = self
                }
                originalInputElementsContainers = tmpInputElementsContainers
            }
        }
        private var originalInputElementsContainers: [Weak<PrimerInputElementDelegateContainer>]? = []
        public weak var cardFormUIManagerDelegate: PrimerCardFormDelegate?
        private(set) public var isCardFormValid: Bool = false {
            didSet {
                DispatchQueue.main.async {
                    self.cardFormUIManagerDelegate?.cardFormUIManager(self, isCardFormValid: self.isCardFormValid)
                }
            }
        }
        private(set) public var paymentMethod: PaymentMethodToken?
        
        deinit {
            log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
        }
        
        public required init() throws {
            try super.init(paymentMethodType: .paymentCard)
            self.requiredInputElementTypes = PrimerHeadlessUniversalCheckout.current.listRequiredInputElementTypes(for: paymentMethodType) ?? []
        }
        
        required public init(paymentMethodType: PrimerPaymentMethodType) throws {
            fatalError("init(paymentMethodType:) has not been implemented")
        }
        
        public override func tokenize(withData data: PrimerHeadlessUniversalCheckoutInputData? = nil) {
            
            PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutTokenizationStarted()
            
            firstly {
                PrimerHeadlessUniversalCheckout.current.validateSession()
            }
            .then { () -> Promise<Void> in
                self.validateInputData()
            }
            .then { () -> Promise<PaymentMethodTokenizationRequest> in
                self.buildRequestBody()
            }
            .then { requestbody -> Promise<PaymentMethodToken> in
                self.tokenize(request: requestbody)
            }
            .done { paymentMethodToken in
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutTokenizationSucceeded(paymentMethodToken: paymentMethodToken, resumeHandler: self)
            }
            .catch { error in
                ErrorHandler.handle(error: error)
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutUniversalCheckoutDidFail(withError: error)
            }
        }
        
        private func validateInputData() -> Promise<Void> {
            return Promise { seal in
                var errors: [PrimerError] = []
                for inputElementType in self.requiredInputElementTypes {
                    if self.inputElements.filter({ $0.type == inputElementType }).isEmpty {
                        let err = PrimerError.missingPrimerInputElement(inputElementType: inputElementType, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        errors.append(err)
                    }
                }
                
                if !errors.isEmpty {
                    let err = PrimerError.underlyingErrors(errors: errors, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    seal.reject(err)
                    return
                }
                
                for inputElement in inputElements {
                    if !inputElement.isValid {
                        let err = PrimerError.invalidValue(key: "input-element", value: inputElement.type.rawValue, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        errors.append(err)
                    }
                }
                
                if !errors.isEmpty {
                    let err = PrimerError.underlyingErrors(errors: errors, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    seal.reject(err)
                    return
                }
                
                seal.fulfill()
            }
        }
        
        private func buildRequestBody() -> Promise<PaymentMethodTokenizationRequest> {
            return Promise { seal in
                switch self.paymentMethodType {
                case .paymentCard:
                    guard let cardnumberField = inputElements.filter({ $0.type == .cardNumber }).first as? PrimerInputTextField,
                          let expiryDateField = inputElements.filter({ $0.type == .expiryDate }).first as? PrimerInputTextField,
                          let cvvField = inputElements.filter({ $0.type == .cvv }).first as? PrimerInputTextField
                    else {
                        let err = PrimerError.invalidValue(key: "input-element", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                        return
                    }
                    
                    guard cardnumberField.isValid,
                          expiryDateField.isValid,
                          cvvField.isValid
                    else {
                        let err = PrimerError.invalidValue(key: "input-element", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                        return
                    }
                    
                    guard let cardNumber = cardnumberField._text,
                          let expiryDate = expiryDateField._text,
                          let cvv = cvvField._text
                    else {
                        let err = PrimerError.invalidValue(key: "input-element", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
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
                            let err = PrimerError.invalidValue(key: "cardholder-name", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                            ErrorHandler.handle(error: err)
                            seal.reject(err)
                            return
                        }
                        
                        cardholderName = cardholderNameField._text
                    }
                    
                    let paymentInstrument = PaymentInstrument(
                        number: PrimerInputElementType.cardNumber.clearFormatting(value: cardNumber) as? String,
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
                    
                    let request = PaymentMethodTokenizationRequest(paymentInstrument: paymentInstrument, paymentFlow: nil)
                    seal.fulfill(request)
                    
                default:
                    fatalError()
                }
            }
        }
        
        private func tokenize(request: PaymentMethodTokenizationRequest) -> Promise<PaymentMethodToken> {
            return Promise { seal in
                let apiClient: PrimerAPIClientProtocol = DependencyContainer.resolve()
                apiClient.tokenizePaymentMethod(clientToken: ClientTokenService.decodedClientToken!, paymentMethodTokenizationRequest: request) { result in
                    switch result {
                    case .success(let paymentMethodToken):
                        self.paymentMethod = paymentMethodToken
                        seal.fulfill(paymentMethodToken)
                        
                    case .failure(let err):
                        let containerErr = PrimerError.underlyingErrors(errors: [err], userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        ErrorHandler.handle(error: containerErr)
                        seal.reject(err)
                    }
                }
            }
        }
        
        // MARK: - INPUT ELEMENTS DELEGATE
        
        public func inputElementShouldFocus(_ sender: PrimerInputElement) -> Bool {
            guard let senderTextField = sender as? PrimerInputTextField else { return true }
            guard let inputElementContainer = originalInputElementsContainers?.filter({ ($0.value?.element as? PrimerInputTextField) == senderTextField }).first else { return true }
            
            if let shouldFocus = inputElementContainer.value?.delegate.inputElementShouldFocus?(sender) {
                return shouldFocus
            } else {
                return true
            }
        }
        
        public func inputElementDidFocus(_ sender: PrimerInputElement) {
            guard let senderTextField = sender as? PrimerInputTextField else { return }
            guard let inputElementContainer = originalInputElementsContainers?.filter({ ($0.value?.element as? PrimerInputTextField) == senderTextField }).first else { return }
            inputElementContainer.value?.delegate.inputElementDidFocus?(sender)
        }
        
        public func inputElementShouldBlur(_ sender: PrimerInputElement) -> Bool {
            guard let senderTextField = sender as? PrimerInputTextField else { return true }
            guard let inputElementContainer = originalInputElementsContainers?.filter({ ($0.value?.element as? PrimerInputTextField) == senderTextField }).first else { return true }
            
            if let shouldBlur = inputElementContainer.value?.delegate.inputElementShouldBlur?(sender) {
                return shouldBlur
            } else {
                return true
            }
        }
        
        public func inputElementDidBlur(_ sender: PrimerInputElement) {
            guard let senderTextField = sender as? PrimerInputTextField else { return }
            guard let inputElementContainer = originalInputElementsContainers?.filter({ ($0.value?.element as? PrimerInputTextField) == senderTextField }).first else { return }
            inputElementContainer.value?.delegate.inputElementDidBlur?(sender)
        }
        
        public func inputElementValueDidChange(_ sender: PrimerInputElement) {
            guard let senderTextField = sender as? PrimerInputTextField else { return }
            guard let inputElementContainer = originalInputElementsContainers?.filter({ ($0.value?.element as? PrimerInputTextField) == senderTextField }).first else { return }
            inputElementContainer.value?.delegate.inputElementValueDidChange?(sender)
        }
        
        public func inputElementDidDetectType(_ sender: PrimerInputElement, type: Any?) {
            guard let senderTextField = sender as? PrimerInputTextField else { return }
            guard let inputElementContainer = originalInputElementsContainers?.filter({ ($0.value?.element as? PrimerInputTextField) == senderTextField }).first else { return }
            
            if let cvvTextField = self.inputElements.filter({ $0.type == .cvv }).first as? PrimerInputTextField {
                cvvTextField.detectedValueType = type
            }
            
            inputElementContainer.value?.delegate.inputElementDidDetectType?(sender, type: type)
        }
        
        public func inputElementValueIsValid(_ sender: PrimerInputElement, isValid: Bool) {
            guard let senderTextField = sender as? PrimerInputTextField else { return }
            guard let inputElementContainer = originalInputElementsContainers?.filter({ ($0.value?.element as? PrimerInputTextField) == senderTextField }).first else { return }
            inputElementContainer.value?.delegate.inputElementValueIsValid?(sender, isValid: isValid)
            
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

extension PrimerHeadlessUniversalCheckout.CardFormUIManager: ResumeHandlerProtocol {
    
    // MARK: - RESUME HANDLER
    
    public func handle(newClientToken clientToken: String) {
        self.handle(clientToken)
    }
    
    public func handle(error: Error) {}
    
    public func handleSuccess() {}
}

extension PrimerHeadlessUniversalCheckout.CardFormUIManager {
    
    private func handle(_ clientToken: String) {
        
        if PrimerHeadlessUniversalCheckout.current.clientToken != clientToken {
            
            ClientTokenService.storeClientToken(clientToken) { error in
                DispatchQueue.main.async {
                    
                    guard error == nil else {
                        var primerErr: PrimerError!
                        if let error = error as? PrimerError {
                            primerErr = error
                        } else {
                            primerErr = PrimerError.generic(message: error!.localizedDescription, userInfo: nil, diagnosticsId: nil)
                        }
                        
                        ErrorHandler.handle(error: error!)
                        PrimerDelegateProxy.primerDidFailWithError(primerErr, data: nil) { errorDecision in
                            // FIXME: Handle decision for HUC
                        }
                        return
                    }
                    
                    self.continueHandleNewClientToken(clientToken)
                }
            }
        } else {
            self.continueHandleNewClientToken(clientToken)
        }
    }
    
    private func continueHandleNewClientToken(_ clientToken: String) {
        
        if let decodedClientToken = ClientTokenService.decodedClientToken,
           decodedClientToken.intent == RequiredActionName.threeDSAuthentication.rawValue {
            
#if canImport(Primer3DS)
            guard let paymentMethod = paymentMethod else {
                DispatchQueue.main.async {
                    let err = InternalError.failedToDecode(message: "Failed to find paymentMethod", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    let containerErr = PrimerError.failedToPerform3DS(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    self.handle(error: containerErr)
                }
                return
            }
            
            let threeDSService = ThreeDSService()
            Primer.shared.intent = .checkout
            
            threeDSService.perform3DS(paymentMethodToken: paymentMethod, protocolVersion: decodedClientToken.env == "PRODUCTION" ? .v1 : .v2, sdkDismissed: nil) { result in
                switch result {
                case .success(let paymentMethodToken):
                    DispatchQueue.main.async {
                        guard let threeDSPostAuthResponse = paymentMethodToken.1,
                              let resumeToken = threeDSPostAuthResponse.resumeToken else {
                            DispatchQueue.main.async {
                                let decoderError = InternalError.failedToDecode(message: "Failed to decode the threeDSPostAuthResponse", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                                let err = PrimerError.failedToPerform3DS(error: decoderError, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                                self.handle(error: err)
                            }
                            return
                        }
                        
                        PrimerDelegateProxy.primerDidResumeWith(resumeToken) { resumeDecision in
                            // FIXME:
                        }
                    }
                    
                case .failure(let err):
                    log(logLevel: .error, message: "Failed to perform 3DS with error \(err as NSError)")
                    let containerErr = PrimerError.failedToPerform3DS(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: containerErr)
                    DispatchQueue.main.async {
                        PrimerDelegateProxy.primerDidFailWithError(containerErr, data: nil) { errorDecision in
                            // FIXME:
                        }
                    }
                }
            }
#else
            DispatchQueue.main.async {
                let err = PrimerError.failedToPerform3DS(error: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                PrimerDelegateProxy.primerDidFailWithError(err, data: nil) { errorDecision in
                    // FIXME: handle the err
                }
            }
#endif
            
        } else {
            let err = PrimerError.invalidValue(key: "resumeToken", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            
            DispatchQueue.main.async {
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutUniversalCheckoutDidFail(withError: err)
            }
        }
    }
}
