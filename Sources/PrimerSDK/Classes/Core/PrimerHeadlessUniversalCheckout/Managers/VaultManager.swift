//
//  VaultManager.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 13/6/23.
//

#if canImport(UIKit)

import SafariServices
import UIKit

extension PrimerHeadlessUniversalCheckout {
    
    public class VaultManager: NSObject {
        
        private(set) var vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData?
        internal(set) var vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod]?
        private(set) var paymentMethodTokenData: PrimerPaymentMethodTokenData?
        private(set) var paymentCheckoutData: PrimerCheckoutData?
        private(set) var resumePaymentId: String?
        private var webViewController: SFSafariViewController?
        private var webViewCompletion: ((_ authorizationToken: String?, _ error: PrimerError?) -> Void)?
        
        // MARK: Public functions
        
        public override init() {
            PrimerInternal.shared.sdkIntegrationType = .headless
            PrimerInternal.shared.intent = .checkout
            
            let sdkEvent = Analytics.Event(
                eventType: .sdkEvent,
                properties: SDKEventProperties(
                    name: "\(Self.self).\(#function)",
                    params: nil))
            Analytics.Service.record(events: [sdkEvent])
            
            super.init()
        }
        
        public func configure() throws {
            try self.validate()
        }
        
        internal func validateAdditionalDataSynchronously(vaultedPaymentMethodId: String, vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData) -> [Error]? {
            self.vaultedPaymentMethodAdditionalData = nil
            var errors: [Error] = []
            
            guard let vaultedPaymentMethod = self.vaultedPaymentMethods?.first(where: { $0.id == vaultedPaymentMethodId }) else {
                let err = PrimerError.invalidVaultedPaymentMethodId(
                    vaultedPaymentMethodId: vaultedPaymentMethodId,
                    userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                errors.append(err)
                return errors
            }
            
            if vaultedPaymentMethod.paymentMethodType == "PAYMENT_CARD" {
                let cardNetwork = CardNetwork(cardNetworkStr: vaultedPaymentMethod.paymentInstrumentData.binData?.network ?? "")
                
                if let vaultedCardAdditionalData = vaultedPaymentMethodAdditionalData as? PrimerVaultedCardAdditionalData {
                    if vaultedCardAdditionalData.cvv.isEmpty {
                        let err = PrimerValidationError.invalidCvv(
                            message: "CVV cannot be blank.",
                            userInfo: [
                                "file": #file,
                                "class": "\(Self.self)",
                                "function": #function,
                                "line": "\(#line)"
                            ],
                            diagnosticsId: UUID().uuidString)
                        errors.append(err)
    
                    } else if !vaultedCardAdditionalData.cvv.isValidCVV(cardNetwork: cardNetwork) {
                        let err = PrimerValidationError.invalidCvv(
                            message: "CVV is not valid.",
                            userInfo: [
                                "file": #file,
                                "class": "\(Self.self)",
                                "function": #function,
                                "line": "\(#line)"
                            ],
                            diagnosticsId: UUID().uuidString)
                        errors.append(err)
                        
                    } else {
                        self.vaultedPaymentMethodAdditionalData = vaultedCardAdditionalData
                    }
                    
                    return errors.isEmpty ? nil : errors
                } else {
                    let err = PrimerValidationError.vaultedPaymentMethodAdditionalDataMismatch(
                        paymentMethodType: vaultedPaymentMethod.paymentMethodType,
                        validVaultedPaymentMethodAdditionalDataType: String(describing: PrimerVaultedCardAdditionalData.self),
                        userInfo: [
                            "file": #file,
                            "class": "\(Self.self)",
                            "function": #function,
                            "line": "\(#line)"
                        ],
                        diagnosticsId: UUID().uuidString)
                    errors.append(err)
                    return errors
                }
            } else {
                // There's no need to validate additional data for payment methods other than PAYMENT_CARD.
                // Return nil to continue
                return nil
            }
        }
        
        public func validate(vaultedPaymentMethodId: String, vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData, completion: @escaping (_ errors: [Error]?) -> Void) {
            DispatchQueue.global(qos: .userInteractive).async {
                let errors = self.validateAdditionalDataSynchronously(vaultedPaymentMethodId: vaultedPaymentMethodId, vaultedPaymentMethodAdditionalData: vaultedPaymentMethodAdditionalData)
                DispatchQueue.main.async {
                    completion(errors)
                }
            }
        }
        
        public func fetchVaultedPaymentMethods(completion: @escaping (_ vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod]?, _ error: Error?) -> Void) {
            let vaultService = VaultService()
            
            firstly {
                vaultService.fetchVaultedPaymentMethods()
            }
            .done {
                self.vaultedPaymentMethods = AppState.current.paymentMethods.compactMap({ $0.vaultedPaymentMethod })
                DispatchQueue.main.async {
                    completion(self.vaultedPaymentMethods, nil)
                }
            }
            .catch { err in
                DispatchQueue.main.async {
                    completion(nil, err)
                }
            }
        }
        
        public func deleteVaultedPaymentMethod(id: String, completion: @escaping (_ error: Error?) -> Void) {
            guard let vaultedPaymentMethod = self.vaultedPaymentMethods?.first(where: { $0.id == id }) else {
                let err = PrimerError.invalidVaultedPaymentMethodId(
                    vaultedPaymentMethodId: id,
                    userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                
                DispatchQueue.main.async {
                    PrimerDelegateProxy.primerDidFailWithError(err, data: self.paymentCheckoutData) { decision in
                        // No need to pass anything
                    }
                }
                return
            }
            
            let vaultService = VaultService()
            
            firstly {
                vaultService.deleteVaultedPaymentMethod(with: id)
            }
            .done {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
            .catch { err in
                DispatchQueue.main.async {
                    completion(err)
                }
            }
        }
        
        public func startPaymentFlow(vaultedPaymentMethodId: String, vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData? = nil) {
            guard let vaultedPaymentMethod = self.vaultedPaymentMethods?.first(where: { $0.id == vaultedPaymentMethodId }) else {
                let err = PrimerError.invalidVaultedPaymentMethodId(
                    vaultedPaymentMethodId: vaultedPaymentMethodId,
                    userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                
                DispatchQueue.main.async {
                    PrimerDelegateProxy.primerDidFailWithError(err, data: self.paymentCheckoutData) { decision in
                        // No need to do anything
                    }
                }
                return
            }
            
            if let vaultedPaymentMethodAdditionalData = vaultedPaymentMethodAdditionalData {
                if let errors = self.validateAdditionalDataSynchronously(vaultedPaymentMethodId: vaultedPaymentMethodId, vaultedPaymentMethodAdditionalData: vaultedPaymentMethodAdditionalData) {
                    DispatchQueue.main.async {
                        var primerError: PrimerErrorProtocol?
                        
                        if errors.count == 1 {
                            if let primerErr = errors.first as? PrimerValidationError {
                                primerError = primerErr
                            } else if let primerErr = errors.first as? PrimerError {
                                primerError = primerErr
                            }
                        }
                        
                        if primerError == nil {
                            let primerErr = PrimerError.underlyingErrors(
                                errors: errors,
                                userInfo: nil,
                                diagnosticsId: UUID().uuidString)
                            primerError = primerErr
                        }
                        
                        PrimerDelegateProxy.primerDidFailWithError(primerError!, data: self.paymentCheckoutData) { decision in
                            // No need to do anything
                        }
                    }
                    return
                }
            }
            
            PrimerDelegateProxy.primerHeadlessUniversalCheckoutDidStartTokenization(for: vaultedPaymentMethod.paymentMethodType)
            
            let tokenizationService: TokenizationServiceProtocol = TokenizationService()
            firstly {
                tokenizationService.exchangePaymentMethodToken(vaultedPaymentMethod.id, vaultedPaymentMethodAdditionalData: self.vaultedPaymentMethodAdditionalData)
            }
            .then { paymentMethodTokenData -> Promise<DecodedJWTToken?> in
                self.paymentMethodTokenData = paymentMethodTokenData
                return self.startPaymentFlowAndFetchDecodedClientToken(withPaymentMethodTokenData: paymentMethodTokenData)
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
                                self.paymentCheckoutData = checkoutData
                                
                                DispatchQueue.main.async {
                                    if PrimerSettings.current.paymentHandling == .auto {
                                        guard let checkoutData = self.paymentCheckoutData, PrimerSettings.current.paymentHandling == .auto else {
                                            let err = PrimerError.generic(
                                                message: "Failed to find checkout data",
                                                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                                                diagnosticsId: UUID().uuidString)
                                            ErrorHandler.handle(error: err)
                                            PrimerDelegateProxy.primerDidFailWithError(err, data: self.paymentCheckoutData) { decision in
                                                // No need to pass anything
                                            }
                                            return
                                        }
                                        
                                        PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
                                    }
                                }
                            }
                            .catch { err in
                                DispatchQueue.main.async {
                                    var primerError: PrimerErrorProtocol
                                    
                                    if let primerErr = err as? PrimerErrorProtocol {
                                        primerError = primerErr
                                    } else {
                                        primerError = PrimerError.underlyingErrors(
                                            errors: [err],
                                            userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                                            diagnosticsId: UUID().uuidString)
                                    }
                                    
                                    PrimerDelegateProxy.primerDidFailWithError(primerError, data: self.paymentCheckoutData) { decision in
                                        // No need to pass anything
                                    }
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                guard let checkoutData = self.paymentCheckoutData else {
                                    let err = PrimerError.generic(
                                        message: "Failed to find checkout data",
                                        userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                                        diagnosticsId: UUID().uuidString)
                                    ErrorHandler.handle(error: err)
                                    PrimerDelegateProxy.primerDidFailWithError(err, data: self.paymentCheckoutData) { decision in
                                        // No need to pass anything
                                    }
                                    return
                                }
                                
                                PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
                            }
                        }
                    }
                    .catch { err in
                        DispatchQueue.main.async {
                            var primerError: PrimerErrorProtocol
                            
                            if let primerErr = err as? PrimerErrorProtocol {
                                primerError = primerErr
                            } else {
                                primerError = PrimerError.underlyingErrors(
                                    errors: [err],
                                    userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                                    diagnosticsId: UUID().uuidString)
                            }
                            
                            PrimerDelegateProxy.primerDidFailWithError(primerError, data: self.paymentCheckoutData) { decision in
                                // No need to pass anything
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        if PrimerSettings.current.paymentHandling == .auto {
                            guard let checkoutData = self.paymentCheckoutData, PrimerSettings.current.paymentHandling == .auto else {
                                let err = PrimerError.generic(
                                    message: "Failed to find checkout data",
                                    userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                                    diagnosticsId: UUID().uuidString)
                                ErrorHandler.handle(error: err)
                                PrimerDelegateProxy.primerDidFailWithError(err, data: self.paymentCheckoutData) { decision in
                                    // No need to pass anything
                                }
                                return
                            }
                            
                            PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
                        }
                    }
                }
            }
            .catch { err in
                DispatchQueue.main.async {
                    var primerError: PrimerErrorProtocol
                    
                    if let primerErr = err as? PrimerErrorProtocol {
                        primerError = primerErr
                    } else {
                        primerError = PrimerError.underlyingErrors(
                            errors: [err],
                            userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                            diagnosticsId: UUID().uuidString)
                    }
                    
                    PrimerDelegateProxy.primerDidFailWithError(primerError, data: self.paymentCheckoutData) { decision in
                        // No need to pass anything
                    }
                }
            }
        }

        // MARK: Private functions
        
        private func validate() throws {
            guard PrimerAPIConfigurationModule.decodedJWTToken != nil,
                  PrimerAPIConfigurationModule.apiConfiguration != nil
            else {
                let err = PrimerError.uninitializedSDKSession(userInfo: nil, diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
            
            guard let customerId = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.customer?.id else {
                let err = PrimerError.invalidClientSessionValue(
                    name: "customer.id",
                    value: nil,
                    allowedValue: "string",
                    userInfo: nil,
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
        }
        
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
                                        let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
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
                                    let err = PrimerError.merchantError(message: message, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                                    merchantErr = err
                                } else {
                                    merchantErr = NSError.emptyDescriptionError
                                }
                                seal.reject(merchantErr)
                            }
                            
                        } else if let resumeDecisionType = resumeDecision.type as? PrimerHeadlessUniversalCheckoutResumeDecision.DecisionType {
                            switch resumeDecisionType {
                            case .continueWithNewClientToken(let newClientToken):
                                let apiConfigurationModule: PrimerAPIConfigurationModuleProtocol = PrimerAPIConfigurationModule()
                                
                                firstly {
                                    apiConfigurationModule.storeRequiredActionClientToken(newClientToken)
                                }
                                .done {
                                    guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                                        let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                                        ErrorHandler.handle(error: err)
                                        throw err
                                    }
                                    
                                    seal.fulfill(decodedJWTToken)
                                }
                                .catch { err in
                                    seal.reject(err)
                                }
                                
                            case .complete:
                                seal.fulfill(nil)
                            }
                            
                        } else {
                            precondition(false)
                        }
                    }
                    
                } else {
                    guard let token = paymentMethodTokenData.token else {
                        let err = PrimerError.invalidClientToken(
                            userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                            diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                        return
                    }
                    
                    firstly {
                        self.handleCreatePaymentEvent(token)
                    }
                    .done { paymentResponse -> Void in
                        guard paymentResponse != nil else {
                            let err = PrimerError.invalidValue(key: "paymentResponse", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
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
                                    let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
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
                    guard let paymentMethodTokenData = paymentMethodTokenData else {
                        let err = InternalError.failedToDecode(message: "Failed to find paymentMethod", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                        let containerErr = PrimerError.failedToPerform3DS(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: containerErr)
                        seal.reject(containerErr)
                        return
                    }
                    
                    let threeDSService = ThreeDSService()
                    threeDSService.perform3DS(
                        paymentMethodTokenData: paymentMethodTokenData,
                        sdkDismissed: nil) { result in
                            DispatchQueue.main.async {
                                switch result {
                                case .success(let resumeToken):
                                    seal.fulfill(resumeToken)
                                    
                                case .failure(let err):
                                    seal.reject(err)
                                }
                            }
                        }
                    
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
                        .ensure {
                            DispatchQueue.main.async { [weak self] in
                                PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)
                                
                                self?.webViewCompletion = nil
                                self?.webViewController?.dismiss(animated: true, completion: { [weak self] in
                                    guard let strongSelf = self else { return }
                                    strongSelf.webViewController = nil
                                })
                            }
                        }
                        .catch { err in
                            if let primerErr = err as? PrimerError {
                                pollingModule?.cancel(withError: primerErr)
                            } else {
                                let err = PrimerError.underlyingErrors(errors: [err], userInfo: nil, diagnosticsId: UUID().uuidString)
                                ErrorHandler.handle(error: err)
                                pollingModule?.cancel(withError: err)
                            }
                            
                            pollingModule = nil
                            seal.reject(err)
                            PrimerInternal.shared.dismiss()
                        }
                        
                    } else {
                        let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                    }
                    
                } else if decodedJWTToken.intent?.contains("_REDIRECTION") == true {
                    if let statusUrlStr = decodedJWTToken.statusUrl,
                       let statusUrl = URL(string: statusUrlStr),
                       decodedJWTToken.intent != nil {
                        
                        if let redirectUrlStr = decodedJWTToken.redirectUrl,
                           let redirectUrl = URL(string: redirectUrlStr) {
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
                                    let err = PrimerError.underlyingErrors(errors: [err], userInfo: nil, diagnosticsId: UUID().uuidString)
                                    ErrorHandler.handle(error: err)
                                    pollingModule?.cancel(withError: err)
                                }
                                
                                pollingModule = nil
                                seal.reject(err)
                                PrimerInternal.shared.dismiss()
                            }
                            
                        } else {
                            let pollingModule: PollingModule? = PollingModule(url: statusUrl)
                            
                            firstly {
                                pollingModule!.start()
                            }
                            .done { resumeToken in
                                seal.fulfill(resumeToken)
                            }
                            .catch { err in
                                seal.reject(err)
                                PrimerInternal.shared.dismiss()
                            }
                        }
                        
                    } else {
                        let error = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                        seal.reject(error)
                    }

                } else {
                    let err = PrimerError.invalidValue(key: "resumeToken", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
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
                                    let err = PrimerError.merchantError(message: message, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
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
                            case .continueWithNewClientToken(_):
                                seal.fulfill(self.paymentCheckoutData)
                                
                            case .complete:
                                seal.fulfill(self.paymentCheckoutData)
                            }
                            
                        } else {
                            precondition(false)
                        }
                    }
                    
                } else {
                    guard let resumePaymentId = self.resumePaymentId else {
                        let resumePaymentIdError = PrimerError.invalidValue(key: "resumePaymentId", value: "Resume Payment ID not valid", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: resumePaymentIdError)
                        seal.reject(resumePaymentIdError)
                        return
                    }
                    
                    firstly {
                        self.handleResumePaymentEvent(resumePaymentId, resumeToken: resumeToken)
                    }
                    .done { paymentResponse -> Void in
                        guard let paymentResponse = paymentResponse else {
                            let err = PrimerError.invalidValue(key: "paymentResponse", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
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
                    
                    if let error = error {
                        if let paymentResponse {
                            self.paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
                        }
                        
                        seal.reject(error)
                        
                    } else if let paymentResponse = paymentResponse {
                        if paymentResponse.id == nil {
                            let err = PrimerError.paymentFailed(
                                description: "Failed to create payment",
                                userInfo: [
                                    "file": #file,
                                    "class": "\(Self.self)",
                                    "function": #function,
                                    "line": "\(#line)"
                                ],
                                diagnosticsId: UUID().uuidString)
                            ErrorHandler.handle(error: err)
                            seal.reject(err)
                            
                        } else if paymentResponse.status == .failed {
                            let err = PrimerError.failedToProcessPayment(
                                paymentId: paymentResponse.id ?? "nil",
                                status: paymentResponse.status.rawValue,
                                userInfo: [
                                    "file": #file,
                                    "class": "\(Self.self)",
                                    "function": #function,
                                    "line": "\(#line)"
                                ],
                                diagnosticsId: UUID().uuidString)
                            ErrorHandler.handle(error: err)
                            seal.reject(err)
                            
                        } else {
                            seal.fulfill(paymentResponse)
                        }
                        
                    } else {
                        let err = PrimerError.paymentFailed(
                            description: "Failed to create payment",
                            userInfo: [
                                "file": #file,
                                "class": "\(Self.self)",
                                "function": #function,
                                "line": "\(#line)"
                            ],
                            diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                    }
                }
            }
        }
        
        private func handleResumePaymentEvent(_ resumePaymentId: String, resumeToken: String) -> Promise<Response.Body.Payment?> {
            return Promise { seal in
                let createResumePaymentService: CreateResumePaymentServiceProtocol = CreateResumePaymentService()
                createResumePaymentService.resumePaymentWithPaymentId(resumePaymentId, paymentResumeRequest: Request.Body.Payment.Resume(token: resumeToken)) { paymentResponse, error in
                    
                    if let error = error {
                        if let paymentResponse {
                            self.paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
                        }
                        
                        seal.reject(error)
                        
                    } else if let paymentResponse = paymentResponse {
                        if paymentResponse.id == nil {
                            let err = PrimerError.paymentFailed(
                                description: "Failed to resume payment",
                                userInfo: [
                                    "file": #file,
                                    "class": "\(Self.self)",
                                    "function": #function,
                                    "line": "\(#line)"
                                ],
                                diagnosticsId: UUID().uuidString)
                            ErrorHandler.handle(error: err)
                            seal.reject(err)
                            
                        } else if paymentResponse.status == .failed {
                            let err = PrimerError.failedToProcessPayment(
                                paymentId: paymentResponse.id ?? "nil",
                                status: paymentResponse.status.rawValue,
                                userInfo: [
                                    "file": #file,
                                    "class": "\(Self.self)",
                                    "function": #function,
                                    "line": "\(#line)"
                                ],
                                diagnosticsId: UUID().uuidString)
                            ErrorHandler.handle(error: err)
                            seal.reject(err)
                            
                        } else {
                            seal.fulfill(paymentResponse)
                        }
                        
                    } else {
                        let err = PrimerError.paymentFailed(
                            description: "Failed to resume payment",
                            userInfo: [
                                "file": #file,
                                "class": "\(Self.self)",
                                "function": #function,
                                "line": "\(#line)"
                            ],
                            diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                    }
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

extension PrimerHeadlessUniversalCheckout.VaultManager: SFSafariViewControllerDelegate {
    
    public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        if let webViewCompletion = webViewCompletion {
            // Cancelled
            let err = PrimerError.cancelled(paymentMethodType: self.paymentMethodTokenData!.paymentInstrumentData!.paymentMethodType!, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
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

extension PrimerHeadlessUniversalCheckout {
    
    public class VaultedPaymentMethod: Codable {
        
        public let id: String
        public let paymentMethodType: String
        public let paymentInstrumentData: Response.Body.Tokenization.PaymentInstrumentData
        public let analyticsId: String
        
        init(
            id: String,
            paymentMethodType: String,
            paymentInstrumentData: Response.Body.Tokenization.PaymentInstrumentData,
            analyticsId: String
        ) {
            self.id = id
            self.paymentMethodType = paymentMethodType
            self.paymentInstrumentData = paymentInstrumentData
            self.analyticsId = analyticsId
        }
    }
}

extension PrimerPaymentMethodTokenData {
    
    var vaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod? {
        guard let id = self.id,
              let paymentMethodType = self.paymentMethodType,
              let paymentInstrumentData = self.paymentInstrumentData,
              let analyticsId = self.analyticsId
        else {
            return nil
        }
            
        return PrimerHeadlessUniversalCheckout.VaultedPaymentMethod(
            id: id,
            paymentMethodType: paymentMethodType,
            paymentInstrumentData: paymentInstrumentData,
            analyticsId: analyticsId
        )
    }
}

#endif
