//
//  PrimerRawDataManager.swift
//  PrimerSDK
//
//  Created by Evangelos on 12/7/22.
//

#if canImport(UIKit)

import Foundation
import SafariServices

@objc
public protocol PrimerRawDataManagerDelegate {
    @objc optional func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager, metadataDidChange metadata: [String: Any]?)
    @objc optional func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager, dataIsValid isValid: Bool, errors: [Error]?)
}

extension PrimerHeadlessUniversalCheckout {
    
    public class RawDataManager: NSObject {
        
        public var delegate: PrimerRawDataManagerDelegate?
        public private(set) var paymentMethodType: String
        public private(set) var requiredInputElementTypes: [PrimerInputElementType]
        public var rawData: PrimerRawData? {
            didSet {
                DispatchQueue.main.async {
                    if let rawCardData = self.rawData as? PrimerCardData {
                        rawCardData.onDataDidChange = {
                            _ = self.validateRawData(self.rawData!)
                            
                            let newCardNetwork = CardNetwork(cardNumber: rawCardData.number)
                            if newCardNetwork != self.cardNetwork {
                                self.cardNetwork = newCardNetwork
                            }
                        }
                        
                        let newCardNetwork = CardNetwork(cardNumber: rawCardData.number)
                        if newCardNetwork != self.cardNetwork {
                            self.cardNetwork = newCardNetwork
                        }
                        
                    } else {
                        if self.cardNetwork != .unknown {
                            self.cardNetwork = .unknown
                        }
                    }
                    
                    _ = self.validateRawData(self.rawData!)
                }
            }
        }
        public private(set) var paymentMethodTokenData: PrimerPaymentMethodTokenData?
        private var resumePaymentId: String?
        public private(set) var paymentCheckoutData: PrimerCheckoutData?
        public private(set) var isDataValid: Bool = false
        private var webViewController: SFSafariViewController?
        private var webViewCompletion: ((_ authorizationToken: String?, _ error: Error?) -> Void)?
        public private(set) var cardNetwork: CardNetwork = .unknown {
            didSet {
                self.delegate?.primerRawDataManager?(self, metadataDidChange: ["cardType": self.cardNetwork.rawValue])
            }
        }
                
        required public init(paymentMethodType: String) throws {
            self.paymentMethodType = paymentMethodType
            
            switch paymentMethodType {
            case PrimerPaymentMethodType.paymentCard.rawValue:
                self.requiredInputElementTypes = [.cardNumber, .expiryDate, .cvv]
                if let checkoutModule = AppState.current.apiConfiguration?.checkoutModules?.filter({ $0.type == "CARD_INFORMATION" }).first,
                   let options = checkoutModule.options as? PrimerAPIConfiguration.CheckoutModule.CardInformationOptions {
                    if options.cardHolderName == true {
                        self.requiredInputElementTypes.append(.cardholderName)
                    }
                }
                
            default:
                self.requiredInputElementTypes = []
                self.paymentMethodType = paymentMethodType
                let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: self.paymentMethodType, userInfo: nil, diagnosticsId: nil)
                throw err
            }
            
            super.init()
        }
        
        public func listRequiredInputElementTypes(for paymentMethodType: String) -> [PrimerInputElementType] {
            return self.requiredInputElementTypes
        }
        
        public func submit() {
            guard let rawData = rawData else {
                let err = PrimerError.invalidValue(key: "rawData", value: nil, userInfo: nil, diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                self.delegate?.primerRawDataManager?(self, dataIsValid: false, errors: [err])
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidFail?(withError: err)
                return
            }
            
            PrimerDelegateProxy.primerHeadlessUniversalCheckoutPreparationDidStart(for: self.paymentMethodType)
            
            firstly {
                PrimerHeadlessUniversalCheckout.current.validateSession()
            }
            .then { () -> Promise<Void> in
                return self.validateRawData(rawData)
            }
            .then { () -> Promise<Void> in
                return self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: PrimerPaymentMethodType.paymentCard.rawValue))
            }
            .then { () -> Promise<PaymentMethodTokenizationRequest> in
                return self.buildRequestBody()
            }
            .then { requestbody -> Promise<PaymentMethodToken> in
                PrimerDelegateProxy.primerHeadlessUniversalCheckoutTokenizationDidStart(for: PrimerPaymentMethodType.paymentCard.rawValue)
                return self.tokenize(request: requestbody)
            }
            .then { paymentMethodTokenData -> Promise<PrimerCheckoutData?> in
                self.paymentMethodTokenData = paymentMethodTokenData
                return self.startPaymentFlow(withPaymentMethodTokenData: paymentMethodTokenData)
            }
            .done { checkoutData in
                if PrimerSettings.current.paymentHandling == .auto, let checkoutData = checkoutData {
                    PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
                }
            }
            .catch { error in
                ErrorHandler.handle(error: error)
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidFail?(withError: error)
            }
        }
        
        internal func validateRawData(_ data: PrimerRawData) -> Promise<Void> {
            return Promise { seal in
                var errors: [PrimerValidationError] = []
                
                if let cardData = data as? PrimerCardData {
                    if !cardData.number.isValidCardNumber {
                        errors.append(PrimerValidationError.invalidCardnumber(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil))
                    }
                    
                    let expiryDate = cardData.expiryMonth + "/" + cardData.expiryYear.suffix(2)
                    
                    if !expiryDate.isValidExpiryDate {
                        errors.append(PrimerValidationError.invalidExpiryDate(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil))
                    }
                    
                    let cardNetwork = CardNetwork(cardNumber: cardData.number)
                    if !cardData.cvv.isValidCVV(cardNetwork: cardNetwork) {
                        errors.append(PrimerValidationError.invalidCvv(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil))
                    }
                    
                    if self.requiredInputElementTypes.contains(PrimerInputElementType.cardholderName) {
                        if !(cardData.cardholderName ?? "").isValidCardholderName {
                            errors.append(PrimerValidationError.invalidCardholderName(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil))
                        }
                    }
                } else {
                    errors.append(PrimerValidationError.invalidRawData(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil))
                }
                
                if !errors.isEmpty {
                    let err = PrimerError.underlyingErrors(errors: errors, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    self.isDataValid = false
                    self.delegate?.primerRawDataManager?(self, dataIsValid: false, errors: errors)
                    seal.reject(err)
                } else {
                    self.isDataValid = true
                    self.delegate?.primerRawDataManager?(self, dataIsValid: true, errors: nil)
                    seal.fulfill()
                }
            }
        }
        
        private func handlePrimerWillCreatePaymentEvent(_ paymentMethodData: PrimerPaymentMethodData) -> Promise<Void> {
            return Promise { seal in
                if Primer.shared.intent == .vault {
                    seal.fulfill()
                } else {
                    let checkoutPaymentMethodType = PrimerCheckoutPaymentMethodType(type: paymentMethodData.type)
                    let checkoutPaymentMethodData = PrimerCheckoutPaymentMethodData(type: checkoutPaymentMethodType)
                    
                    PrimerDelegateProxy.primerWillCreatePaymentWithData(checkoutPaymentMethodData, decisionHandler: { paymentCreationDecision in
                        switch paymentCreationDecision.type {
                        case .abort(let errorMessage):
                            let error = PrimerError.merchantError(message: errorMessage ?? "", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                            seal.reject(error)
                        case .continue:
                            seal.fulfill()
                        }
                    })
                }
            }
        }
        
        private func buildRequestBody() -> Promise<PaymentMethodTokenizationRequest> {
            return Promise { seal in
                switch self.paymentMethodType {
                case PrimerPaymentMethodType.paymentCard.rawValue:
                    let paymentInstrument = PaymentInstrument(
                        number: PrimerInputElementType.cardNumber.clearFormatting(value: (self.rawData as? PrimerCardData)?.number ?? "") as? String,
                        cvv: (self.rawData as? PrimerCardData)?.cvv,
                        expirationMonth: (self.rawData as? PrimerCardData)?.expiryMonth,
                        expirationYear: (self.rawData as? PrimerCardData)?.expiryYear,
                        cardholderName: (self.rawData as? PrimerCardData)?.cardholderName,
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
        
        private func tokenize(request: PaymentMethodTokenizationRequest) -> Promise<PrimerPaymentMethodTokenData> {
            return Promise { seal in
                let apiClient: PrimerAPIClientProtocol = DependencyContainer.resolve()
                apiClient.tokenizePaymentMethod(clientToken: ClientTokenService.decodedClientToken!, paymentMethodTokenizationRequest: request) { result in
                    switch result {
                    case .success(let paymentMethodTokenData):
                        self.paymentMethodTokenData = paymentMethodTokenData
                        seal.fulfill(paymentMethodTokenData)
                        
                    case .failure(let err):
                        let containerErr = PrimerError.underlyingErrors(errors: [err], userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        ErrorHandler.handle(error: containerErr)
                        seal.reject(err)
                    }
                }
            }
        }
        
        private func startPaymentFlow(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<PrimerCheckoutData?> {
            return Promise { seal in
                firstly {
                    self.startPaymentFlowAndFetchDecodedClientToken(withPaymentMethodTokenData: paymentMethodTokenData)
                }
                .done { decodedClientToken in
                    if let decodedClientToken = decodedClientToken {
                        firstly {
                            self.handleDecodedClientTokenIfNeeded(decodedClientToken)
                        }
                        .done { resumeToken in
                            if let resumeToken = resumeToken {
                                firstly {
                                    self.handleResumeStepsBasedOnSDKSettings(resumeToken: resumeToken)
                                }
                                .done { checkoutData in
                                    seal.fulfill(checkoutData)
                                }
                                .catch { err in
                                    seal.reject(err)
                                }
                            } else {
                                seal.fulfill(nil)
                            }
                        }
                        .catch { err in
                            seal.reject(err)
                        }
                    } else {
                        seal.fulfill(self.paymentCheckoutData)
                    }
                }
                .catch { err in
                    seal.reject(err)
                }
            }
        }
        
        // This function will do one of the two following:
        //     - Wait a response from the merchant, via the delegate function. The response can be:
        //         - A new client token
        //         - Success
        //         - Error
        //     - Perform the payment internally, and get a response from our BE. The response will
        //       be a Payment response. The can contain:
        //         - A required action with a new client token
        //         - Be successful
        //         - Has failed
        //
        // Therefore, return:
        //     - A decoded client token
        //     - nil for success
        //     - Reject with an error
        private func startPaymentFlowAndFetchDecodedClientToken(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<DecodedClientToken?> {
            return Promise { seal in
                if PrimerSettings.current.paymentHandling == .manual {
                    PrimerDelegateProxy.primerDidTokenizePaymentMethod(paymentMethodTokenData) { resumeDecision in
                        switch resumeDecision.type {
                        case .succeed:
                            seal.fulfill(nil)
                            
                        case .continueWithNewClientToken(let newClientToken):
                            firstly {
                                ClientTokenService.storeClientToken(newClientToken)
                            }
                            .then { () -> Promise<Void> in
                                let configurationService = PrimerAPIConfigurationService(requestDisplayMetadata: true)
                                return configurationService.fetchConfiguration()
                            }
                            .done {
                                guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                                    let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                                    ErrorHandler.handle(error: err)
                                    throw err
                                }
                                
                                seal.fulfill(decodedClientToken)
                            }
                            .catch { err in
                                seal.reject(err)
                            }
                            
                        case .fail(let message):
                            var merchantErr: Error!
                            if let message = message {
                                let err = PrimerError.merchantError(message: message, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                                merchantErr = err
                            } else {
                                merchantErr = NSError.emptyDescriptionError
                            }
                            seal.reject(merchantErr)
                        }
                    }
                    
                } else {
                    guard let paymentMethodTokenString = paymentMethodTokenData.token else {
                        let paymentMethodTokenError = PrimerError.invalidValue(key: "resumePaymentId", value: "Payment method token not valid", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        ErrorHandler.handle(error: paymentMethodTokenError)
                        throw paymentMethodTokenError
                    }
                    
                    firstly {
                        self.handleCreatePaymentEvent(paymentMethodTokenString)
                    }
                    .done { paymentResponse -> Void in
                        guard paymentResponse != nil else {
                            let err = PrimerError.invalidValue(key: "paymentResponse", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                            throw err
                        }
                        
                        self.paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse!))
                        self.resumePaymentId = paymentResponse!.id
                        
                        if let requiredAction = paymentResponse!.requiredAction {
                            firstly {
                                ClientTokenService.storeClientToken(requiredAction.clientToken)
                            }
                            .done { checkoutData in
                                guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                                    let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                                    ErrorHandler.handle(error: err)
                                    throw err
                                }
                                
                                seal.fulfill(decodedClientToken)
                            }
                            .catch { err in
                                seal.reject(err)
                            }
                            
                        } else {
                            seal.fulfill(nil)
                        }
                    }
                    .catch { err in
                        seal.reject(err)
                    }
                }
            }
        }
        
        private func handleDecodedClientTokenIfNeeded(_ decodedClientToken: DecodedClientToken) -> Promise<String?> {
            return Promise { seal in
                if decodedClientToken.intent == RequiredActionName.threeDSAuthentication.rawValue {
#if canImport(Primer3DS)
                    guard let paymentMethodTokenData = paymentMethodTokenData else {
                        let err = InternalError.failedToDecode(message: "Failed to find paymentMethod", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        let containerErr = PrimerError.failedToPerform3DS(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        ErrorHandler.handle(error: containerErr)
                        seal.reject(containerErr)
                        return
                    }
                    
                    let threeDSService = ThreeDSService()
                    threeDSService.perform3DS(paymentMethodToken: paymentMethodTokenData, protocolVersion: decodedClientToken.env == "PRODUCTION" ? .v1 : .v2, sdkDismissed: nil) { result in
                        switch result {
                        case .success(let paymentMethodToken):
                            DispatchQueue.main.async {
                                guard let threeDSPostAuthResponse = paymentMethodToken.1,
                                      let resumeToken = threeDSPostAuthResponse.resumeToken else {
                                    let decoderError = InternalError.failedToDecode(message: "Failed to decode the threeDSPostAuthResponse", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                                    let err = PrimerError.failedToPerform3DS(error: decoderError, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                                    ErrorHandler.handle(error: err)
                                    seal.reject(err)
                                    return
                                }
                                
                                seal.fulfill(resumeToken)
                            }
                            
                        case .failure(let err):
                            let containerErr = PrimerError.failedToPerform3DS(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                            ErrorHandler.handle(error: containerErr)
                            seal.reject(containerErr)
                        }
                    }
#else
                    let err = PrimerError.failedToPerform3DS(error: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
#endif
                    
                } else if decodedClientToken.intent == RequiredActionName.processor3DS.rawValue {
                    if let redirectUrlStr = decodedClientToken.redirectUrl,
                       let redirectUrl = URL(string: redirectUrlStr),
                       let statusUrlStr = decodedClientToken.statusUrl,
                       let statusUrl = URL(string: statusUrlStr),
                       decodedClientToken.intent != nil {
                        
                        DispatchQueue.main.async {
                            UIApplication.shared.endIgnoringInteractionEvents()
                        }
                        
                        firstly {
                            self.presentWeb3DS(with: redirectUrl)
                        }
                        .then { () -> Promise<String> in
                            return self.startPolling(on: statusUrl)
                        }
                        .done { resumeToken in
                            seal.fulfill(resumeToken)
                        }
                        .catch { err in
                            seal.reject(err)
                        }
                    } else {
                        let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                    }
                } else {
                    let err = PrimerError.invalidValue(key: "resumeToken", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                }
            }
        }
        
        private func handleResumeStepsBasedOnSDKSettings(resumeToken: String) -> Promise<PrimerCheckoutData?> {
            return Promise { seal in
                if PrimerSettings.current.paymentHandling == .manual {
                    PrimerDelegateProxy.primerDidResumeWith(resumeToken) { resumeDecision in
                        switch resumeDecision.type {
                        case .fail(let message):
                            var merchantErr: Error!
                            if let message = message {
                                let err = PrimerError.merchantError(message: message, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                                merchantErr = err
                            } else {
                                merchantErr = NSError.emptyDescriptionError
                            }
                            seal.reject(merchantErr)
                            
                        case .succeed:
                            seal.fulfill(nil)
                            
                        case .continueWithNewClientToken:
                            seal.fulfill(nil)
                        }
                    }
                    
                } else {
                    guard let resumePaymentId = self.resumePaymentId else {
                        let resumePaymentIdError = PrimerError.invalidValue(key: "resumePaymentId", value: "Resume Payment ID not valid", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        ErrorHandler.handle(error: resumePaymentIdError)
                        seal.reject(resumePaymentIdError)
                        return
                    }
                    
                    firstly {
                        self.handleResumePaymentEvent(resumePaymentId, resumeToken: resumeToken)
                    }
                    .done { paymentResponse -> Void in
                        guard let paymentResponse = paymentResponse else {
                            let err = PrimerError.invalidValue(key: "paymentResponse", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                            ErrorHandler.handle(error: err)
                            throw err
                        }
                        
                        self.paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
                        seal.fulfill(self.paymentCheckoutData)
                    }
                    .catch { err in
                        seal.reject(err)
                    }
                }
            }
        }
        
        private func handleCreatePaymentEvent(_ paymentMethodData: String) -> Promise<Payment.Response?> {
            return Promise { seal in
                let createResumePaymentService: CreateResumePaymentServiceProtocol = DependencyContainer.resolve()
                createResumePaymentService.createPayment(paymentRequest: Payment.CreateRequest(token: paymentMethodData)) { paymentResponse, error in
                    guard error == nil else {
                        seal.reject(error!)
                        return
                    }
                    
                    guard let status = paymentResponse?.status, status != .failed else {
                        seal.reject(PrimerError.paymentFailed(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil))
                        return
                    }
                    
                    if let paymentFailureReason = paymentResponse?.paymentFailureReason,
                       let paymentErrorCode = PrimerPaymentErrorCode(rawValue: paymentFailureReason),
                       let error = PrimerError.simplifiedErrorFromErrorID(paymentErrorCode, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"]) {
                        seal.reject(error)
                        return
                    }
                    
                    seal.fulfill(paymentResponse)
                }
            }
        }
        
        private func handleResumePaymentEvent(_ resumePaymentId: String, resumeToken: String) -> Promise<Payment.Response?> {
            return Promise { seal in
                let createResumePaymentService: CreateResumePaymentServiceProtocol = DependencyContainer.resolve()
                createResumePaymentService.resumePaymentWithPaymentId(resumePaymentId, paymentResumeRequest: Payment.ResumeRequest(token: resumeToken)) { paymentResponse, error in
                    
                    guard error == nil else {
                        seal.reject(error!)
                        return
                    }
                    
                    guard let status = paymentResponse?.status, status != .failed else {
                        seal.reject(PrimerError.paymentFailed(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil))
                        return
                    }
                    
                    if let paymentFailureReason = paymentResponse?.paymentFailureReason,
                       let paymentErrorCode = PrimerPaymentErrorCode(rawValue: paymentFailureReason),
                       let error = PrimerError.simplifiedErrorFromErrorID(paymentErrorCode, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"]) {
                        seal.reject(error)
                        return
                    }
                    
                    seal.fulfill(paymentResponse)
                }
            }
        }
        
        private func presentWeb3DS(with redirectUrl: URL) -> Promise<Void> {
            return Promise { seal in
                self.webViewController = SFSafariViewController(url: redirectUrl)
                self.webViewController!.delegate = self
                
                self.webViewCompletion = { (id, err) in
                    if let err = err {
                        seal.reject(err)
                    }
                }
                
                DispatchQueue.main.async {
                    Primer.shared.primerRootVC?.present(self.webViewController!, animated: true, completion: {
                        DispatchQueue.main.async {
                            seal.fulfill()
                        }
                    })
                }
            }
        }
        
        private func startPolling(on url: URL) -> Promise<String> {
            return Promise { seal in
                self.startPolling(on: url) { resumeToken, err in
                    if let err = err {
                        seal.reject(err)
                    } else if let resumeToken = resumeToken {
                        seal.fulfill(resumeToken)
                    } else {
                        assert(true, "Completion handler should always return a value or an error")
                    }
                }
            }
        }
        
        private func startPolling(on url: URL, completion: @escaping (String?, Error?) -> Void) {
            let client: PrimerAPIClientProtocol = DependencyContainer.resolve()
            client.poll(clientToken: ClientTokenService.decodedClientToken, url: url.absoluteString) { result in
                if self.webViewCompletion == nil {
                    let err = PrimerError.cancelled(paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    completion(nil, err)
                    return
                }
                
                switch result {
                case .success(let res):
                    if res.status == .pending {
                        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                            self.startPolling(on: url, completion: completion)
                        }
                    } else if res.status == .complete {
                        completion(res.id, nil)
                    } else {
                        let err = PrimerError.generic(message: "Should never end up here", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        ErrorHandler.handle(error: err)
                    }
                case .failure(let err):
                    ErrorHandler.handle(error: err)
                    // Retry
                    Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
                        self.startPolling(on: url, completion: completion)
                    }
                }
            }
        }
    }
    
}

extension PrimerHeadlessUniversalCheckout.RawDataManager: SFSafariViewControllerDelegate {
    
    private func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        if let webViewCompletion = webViewCompletion {
            // Cancelled
            let err = PrimerError.cancelled(paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            webViewCompletion(nil, err)
        }
        
        self.webViewCompletion = nil
    }
}

#endif
