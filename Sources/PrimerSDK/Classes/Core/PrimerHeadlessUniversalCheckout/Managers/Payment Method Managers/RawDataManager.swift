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
public protocol PrimerHeadlessUniversalCheckoutRawDataManagerDelegate {
    @objc optional func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager, metadataDidChange metadata: [String: Any]?)
    @objc optional func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager, dataIsValid isValid: Bool, errors: [Error]?)
}

protocol PrimerRawDataTokenizationBuilderProtocol {
    
    var requiredInputElementTypes: [PrimerInputElementType] { get }
    var paymentMethodType: String { get }
    var rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager? { get }
    var isDataValid: Bool { get set }
    var rawData: PrimerRawData? { get set }
    
    init(paymentMethodType: String)
    func configureRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager)
    func makeRequestBodyWithRawData(_ data: PrimerRawData) -> Promise<Request.Body.Tokenization>
    func validateRawData(_ data: PrimerRawData) -> Promise<Void>
}

extension PrimerHeadlessUniversalCheckout {
    
    public class RawDataManager: NSObject {
        
        public var delegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate?
        public private(set) var paymentMethodType: String
        public var rawData: PrimerRawData? {
            didSet {
                DispatchQueue.main.async {
                    self.rawDataTokenizationBuilder.rawData = self.rawData
                }
            }
        }
        public private(set) var paymentMethodTokenData: PrimerPaymentMethodTokenData?
        public var requiredInputElementTypes: [PrimerInputElementType] {
            self.rawDataTokenizationBuilder.requiredInputElementTypes
        }
        private var resumePaymentId: String?
        private var rawDataTokenizationBuilder: PrimerRawDataTokenizationBuilderProtocol
        public private(set) var paymentCheckoutData: PrimerCheckoutData?
        public private(set) var isDataValid: Bool = false
        private var webViewController: SFSafariViewController?
        private var webViewCompletion: ((_ authorizationToken: String?, _ error: PrimerError?) -> Void)?
        var initializationData: PrimerInitializationData?
        
        required public init(paymentMethodType: String, delegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate? = nil) throws {
            
            self.delegate = delegate
            
            guard PrimerPaymentMethod.getPaymentMethod(withType: paymentMethodType) != nil else {
                let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType, userInfo: nil, diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                throw err
            }
            
            self.paymentMethodType = paymentMethodType
            
            switch paymentMethodType {
                
            case PrimerPaymentMethodType.paymentCard.rawValue:
                self.rawDataTokenizationBuilder = PrimerRawCardDataTokenizationBuilder(paymentMethodType:PrimerPaymentMethodType.paymentCard.rawValue)
            
            case PrimerPaymentMethodType.adyenBancontactCard.rawValue:
                self.rawDataTokenizationBuilder = PrimerBancontactRawCardDataRedirectTokenizationBuilder(paymentMethodType: paymentMethodType)
                
            case PrimerPaymentMethodType.xenditOvo.rawValue,
                PrimerPaymentMethodType.adyenMBWay.rawValue:
                self.rawDataTokenizationBuilder = PrimerRawPhoneNumberDataTokenizationBuilder(paymentMethodType: paymentMethodType)
                
            case PrimerPaymentMethodType.xenditRetailOutlets.rawValue:
                self.rawDataTokenizationBuilder = PrimerRawRetailerDataTokenizationBuilder(paymentMethodType: paymentMethodType)
                
            default:
                let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType, userInfo: nil, diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                throw err
            }
            
            super.init()
            
            self.rawDataTokenizationBuilder.configureRawDataManager(self)
        }
        
        public func listRequiredInputElementTypes(for paymentMethodType: String) -> [PrimerInputElementType] {
            return self.rawDataTokenizationBuilder.requiredInputElementTypes
        }
                
        public func submit() {
            
            guard let rawData = rawData else {
                let err = PrimerError.invalidValue(key: "rawData", value: nil, userInfo: nil, diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                self.delegate?.primerRawDataManager?(self, dataIsValid: false, errors: [err])
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidFail?(withError: err)
                return
            }
            
            if let rawCardData = rawData as? PrimerCardData {
                do {
                    try rawCardData.validate()
                } catch {
                    self.delegate?.primerRawDataManager?(self, dataIsValid: false, errors: [error])
                    PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidFail?(withError: error)
                    return
                }
            }
            
            PrimerDelegateProxy.primerHeadlessUniversalCheckoutUIDidStartPreparation(for: self.paymentMethodType)
            
            firstly {
                PrimerHeadlessUniversalCheckout.current.validateSession()
            }
            .then { () -> Promise<Void> in
                return self.validateRawData(rawData)
            }
            .then { () -> Promise<Void> in
                return self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.paymentMethodType))
            }
            .then { () -> Promise<Request.Body.Tokenization> in
                return self.makeRequestBody()
            }
            .then { requestBody -> Promise<PrimerPaymentMethodTokenData> in
                PrimerDelegateProxy.primerHeadlessUniversalCheckoutDidStartTokenization(for: self.paymentMethodType)
                let tokenizationService: TokenizationServiceProtocol = TokenizationService()
                return tokenizationService.tokenize(requestBody: requestBody)
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
            return rawDataTokenizationBuilder.validateRawData(data)
        }
        
        private func handlePrimerWillCreatePaymentEvent(_ paymentMethodData: PrimerPaymentMethodData) -> Promise<Void> {
            return Promise { seal in
                if PrimerInternal.shared.intent == .vault {
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
        
        private func makeRequestBody() -> Promise<Request.Body.Tokenization> {
            
            return Promise { seal in
                guard let rawData = self.rawData else {
                    let err = PrimerValidationError.invalidRawData(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    seal.reject(err)
                    return
                }
                
                firstly {
                    rawDataTokenizationBuilder.makeRequestBodyWithRawData(rawData)
                }.done { requestbody in
                    seal.fulfill(requestbody)
                }.catch { err in
                    seal.reject(err)
                }
            }
        }
        
        private func startPaymentFlow(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<PrimerCheckoutData?> {
            return Promise { seal in
                firstly {
                    self.startPaymentFlowAndFetchDecodedClientToken(withPaymentMethodTokenData: paymentMethodTokenData)
                }
                .done { decodedJWTToken in
                    if let decodedJWTToken = decodedJWTToken {
                        firstly {
                            self.handleDecodedClientTokenIfNeeded(decodedJWTToken)
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
                                seal.fulfill(self.paymentCheckoutData)
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
        private func startPaymentFlowAndFetchDecodedClientToken(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<DecodedJWTToken?> {
            return Promise { seal in
                if PrimerSettings.current.paymentHandling == .manual {
                    PrimerDelegateProxy.primerDidTokenizePaymentMethod(paymentMethodTokenData) { resumeDecision in
                        if let resumeType = resumeDecision.type as? PrimerResumeDecision.DecisionType {
                            switch resumeType {
                            case .succeed:
                                seal.fulfill(nil)
                                
                            case .continueWithNewClientToken(let newClientToken):
                                let apiConfigurationModule = PrimerAPIConfigurationModule()
                            
                            firstly {
                                apiConfigurationModule.storeRequiredActionClientToken(newClientToken)
                            }
                            .done {
                                guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                                    let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                                    ErrorHandler.handle(error: err)
                                    throw err
                                }
                                
                                seal.fulfill(decodedJWTToken)
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
                            
                        } else {
                            precondition(false)
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
                            let apiConfigurationModule = PrimerAPIConfigurationModule()
                            
                            firstly {
                                apiConfigurationModule.storeRequiredActionClientToken(requiredAction.clientToken)
                            }
                            .done {
                                guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                                    let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                                    ErrorHandler.handle(error: err)
                                    throw err
                                }
                                
                                seal.fulfill(decodedJWTToken)
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
        
        private func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken) -> Promise<String?> {
            return Promise { seal in
                if decodedJWTToken.intent == RequiredActionName.threeDSAuthentication.rawValue {
#if canImport(Primer3DS)
                    guard let paymentMethodTokenData = paymentMethodTokenData else {
                        let err = InternalError.failedToDecode(message: "Failed to find paymentMethod", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        let containerErr = PrimerError.failedToPerform3DS(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        ErrorHandler.handle(error: containerErr)
                        seal.reject(containerErr)
                        return
                    }
                    
                    let threeDSService = ThreeDSService()
                    threeDSService.perform3DS(paymentMethodTokenData: paymentMethodTokenData, protocolVersion: decodedJWTToken.env == "PRODUCTION" ? .v1 : .v2, sdkDismissed: nil) { result in
                        switch result {
                        case .success(let resumeToken):
                            DispatchQueue.main.async {
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
                    
                } else if decodedJWTToken.intent == RequiredActionName.processor3DS.rawValue {
                    if let redirectUrlStr = decodedJWTToken.redirectUrl,
                       let redirectUrl = URL(string: redirectUrlStr),
                       let statusUrlStr = decodedJWTToken.statusUrl,
                       let statusUrl = URL(string: statusUrlStr),
                       decodedJWTToken.intent != nil {
                        
                        DispatchQueue.main.async {
                            PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
                        }
                        
                        var pollingModule: PollingModule? = PollingModule(url: statusUrl)
                        
                        firstly {
                            self.presentWebRedirectViewControllerWithRedirectUrl(redirectUrl)
                        }
                        .then { () -> Promise<String> in
                            self.webViewCompletion = { (id, err) in
                                if let err = err {
                                    pollingModule?.cancel(withError: err)
                                    pollingModule = nil
                                }
                            }
                            return pollingModule!.start()
                        }
                        .done { resumeToken in
                            seal.fulfill(resumeToken)
                        }
                        .catch { err in
                            if let primerErr = err as? PrimerError {
                                pollingModule?.cancel(withError: primerErr)
                            } else {
                                let err = PrimerError.underlyingErrors(errors: [err], userInfo: nil, diagnosticsId: nil)
                                ErrorHandler.handle(error: err)
                                pollingModule?.cancel(withError: err)
                            }
                            
                            pollingModule = nil
                            seal.reject(err)
                            PrimerInternal.shared.dismiss()
                        }
                        
                    } else {
                        let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                    }
                    
                } else if decodedJWTToken.intent?.contains("_REDIRECTION") == true {
                    if let redirectUrlStr = decodedJWTToken.redirectUrl,
                       let redirectUrl = URL(string: redirectUrlStr),
                       let statusUrlStr = decodedJWTToken.statusUrl,
                       let statusUrl = URL(string: statusUrlStr),
                       decodedJWTToken.intent != nil {
                        
                        DispatchQueue.main.async {
                            PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
                        }
                        
                        var pollingModule: PollingModule? = PollingModule(url: statusUrl)
                        
                        firstly {
                            self.presentWebRedirectViewControllerWithRedirectUrl(redirectUrl)
                        }
                        .then { () -> Promise<String> in
                            self.webViewCompletion = { (id, err) in
                                if let err = err {
                                    pollingModule?.cancel(withError: err)
                                    pollingModule = nil
                                }
                            }
                            return pollingModule!.start()
                        }
                        .done { resumeToken in
                            seal.fulfill(resumeToken)
                        }
                        .catch { err in
                            if let primerErr = err as? PrimerError {
                                pollingModule?.cancel(withError: primerErr)
                            } else {
                                let err = PrimerError.underlyingErrors(errors: [err], userInfo: nil, diagnosticsId: nil)
                                ErrorHandler.handle(error: err)
                                pollingModule?.cancel(withError: err)
                            }
                            
                            pollingModule = nil
                            seal.reject(err)
                            PrimerInternal.shared.dismiss()
                        }
                        
                    } else {
                        let error = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        seal.reject(error)
                    }

                } else if decodedJWTToken.intent == RequiredActionName.paymentMethodVoucher.rawValue {
                    
                    let isManualPaymentHandling = PrimerSettings.current.paymentHandling == .manual
                    var additionalInfo: PrimerCheckoutAdditionalInfo?

                    switch self.paymentMethodType {
                    case PrimerPaymentMethodType.xenditRetailOutlets.rawValue:

                        guard let decodedExpiresAt = decodedJWTToken.expiresAt else {
                            let err = PrimerError.invalidValue(key: "decodedJWTToken.expiresAt", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                            ErrorHandler.handle(error: err)
                            seal.reject(err)
                            return
                        }
                        
                        guard let decodedVoucherReference = decodedJWTToken.reference else {
                            let err = PrimerError.invalidValue(key: "decodedJWTToken.reference", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                            ErrorHandler.handle(error: err)
                            seal.reject(err)
                            return
                        }

                        guard let selectedRetailer = rawData as? PrimerRawRetailerData,
                              let selectedRetailerName = (initializationData as? RetailOutletsList)?.result.first(where: { $0.id == selectedRetailer.id })?.name else {
                            let err = PrimerError.invalidValue(key: "rawData.id", value: "Invalid Retailer Identifier", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                            ErrorHandler.handle(error: err)
                            seal.reject(err)
                            return
                        }
                        
                        let formatter = DateFormatter().withExpirationDisplayDateFormat()
                        additionalInfo = XenditCheckoutVoucherAdditionalInfo(expiresAt: formatter.string(from: decodedExpiresAt),
                                                                                   couponCode: decodedVoucherReference,
                                                                                   retailerName: selectedRetailerName)
                        self.paymentCheckoutData?.additionalInfo = additionalInfo
                        
                    default:
                        log(logLevel: .info, title: "UNHANDLED PAYMENT METHOD RESULT", message: self.paymentMethodType, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: #function, line: nil)
                        break
                    }
                    
                    if isManualPaymentHandling {
                        PrimerDelegateProxy.primerDidEnterResumePendingWithPaymentAdditionalInfo(additionalInfo)
                        seal.fulfill(nil)
                    } else {
                        seal.fulfill(nil)
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
                        if let resumeDecisionType = resumeDecision.type as? PrimerResumeDecision.DecisionType {
                            switch resumeDecisionType {
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
                            
                        } else if let resumeDecisionType = resumeDecision.type as? PrimerHeadlessUniversalCheckoutResumeDecision.DecisionType {
                            switch resumeDecisionType {
                            case .continueWithNewClientToken:
                                seal.fulfill(nil)
                            case .complete:
                                seal.fulfill(nil)
                            }
                            
                        } else {
                          precondition(false)
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
        
        private func handleCreatePaymentEvent(_ paymentMethodData: String) -> Promise<Response.Body.Payment?> {
            return Promise { seal in
                let createResumePaymentService: CreateResumePaymentServiceProtocol = CreateResumePaymentService()
                createResumePaymentService.createPayment(paymentRequest: Request.Body.Payment.Create(token: paymentMethodData)) { paymentResponse, error in
                    guard error == nil else {
                        seal.reject(error!)
                        return
                    }
                    
                    guard let status = paymentResponse?.status, status != .failed else {
                        seal.reject(PrimerError.paymentFailed(
                            description: "Failed to create/resume payment",
                            userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                            diagnosticsId: nil))
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
        
        private func handleResumePaymentEvent(_ resumePaymentId: String, resumeToken: String) -> Promise<Response.Body.Payment?> {
            return Promise { seal in
                let createResumePaymentService: CreateResumePaymentServiceProtocol = CreateResumePaymentService()
                createResumePaymentService.resumePaymentWithPaymentId(resumePaymentId, paymentResumeRequest: Request.Body.Payment.Resume(token: resumeToken)) { paymentResponse, error in
                    
                    guard error == nil else {
                        seal.reject(error!)
                        return
                    }
                    
                    guard let status = paymentResponse?.status, status != .failed else {
                        seal.reject(PrimerError.paymentFailed(
                            description: "Failed to create/resume payment",
                            userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                            diagnosticsId: nil))
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
        
        private func presentWebRedirectViewControllerWithRedirectUrl(_ redirectUrl: URL) -> Promise<Void> {
            return Promise { seal in
                self.webViewController = SFSafariViewController(url: redirectUrl)
                self.webViewController!.delegate = self
                
                self.webViewCompletion = { (id, err) in
                    if let err = err {
                        seal.reject(err)
                    }
                }
                
                DispatchQueue.main.async {
                    if PrimerUIManager.primerRootViewController == nil {
                        firstly {
                            PrimerUIManager.prepareRootViewController()
                        }
                        .done {
                            PrimerUIManager.primerRootViewController?.present(self.webViewController!, animated: true, completion: {
                                DispatchQueue.main.async {
                                    seal.fulfill()
                                }
                            })
                        }
                        .catch { _ in }
                    } else {
                        PrimerUIManager.primerRootViewController?.present(self.webViewController!, animated: true, completion: {
                            DispatchQueue.main.async {
                                seal.fulfill()
                            }
                        })
                    }
                    
                }
            }
        }
    }
}

extension PrimerHeadlessUniversalCheckout.RawDataManager: SFSafariViewControllerDelegate {
    
    public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        if let webViewCompletion = webViewCompletion {
            // Cancelled
            let err = PrimerError.cancelled(paymentMethodType: self.paymentMethodType, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            webViewCompletion(nil, err)
        }

        self.webViewCompletion = nil
    }
    
    public func safariViewController(_ controller: SFSafariViewController, initialLoadDidRedirectTo URL: URL) {
        if URL.absoluteString.hasSuffix("primer.io/static/loading.html") || URL.absoluteString.hasSuffix("primer.io/static/loading-spinner.html") {
            PrimerUIManager.dismissPrimerUI(animated: true)
        }
    }
}

#endif
