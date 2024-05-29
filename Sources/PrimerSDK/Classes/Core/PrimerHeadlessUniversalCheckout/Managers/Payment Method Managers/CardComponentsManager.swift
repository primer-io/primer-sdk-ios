//
//  PrimerCheckoutComponentsUIManager.swift
//  PrimerSDK
//
//  Created by Evangelos on 9/2/22.
//

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable file_length
// swiftlint:disable function_body_length
// swiftlint:disable type_body_length

import Foundation
import SafariServices

public protocol PrimerHeadlessUniversalCheckoutInputData {}
// swiftlint:disable type_name
@available(*, deprecated, message: "CardComponentsManager is no longer supported, please use PrimerHeadlessUniversalCheckout instead")
public protocol PrimerHeadlessUniversalCheckoutCardComponentsManagerDelegate: AnyObject {
    func cardComponentsManager(_ cardComponentsManager: PrimerHeadlessUniversalCheckout.CardComponentsManager,
                               isCardFormValid: Bool)
}
// swiftlint:enable type_name

extension PrimerHeadlessUniversalCheckout {

    @available(*, deprecated, message: "CardComponentsManager is no longer supported, please use PrimerHeadlessUniversalCheckout instead")
    public final class CardComponentsManager: NSObject, PrimerInputElementDelegate, LogReporter {

        private(set) public var paymentMethodType: String
        private let appState: AppStateProtocol = AppState.current
        public var requiredInputElementTypes: [PrimerInputElementType] {
            let sdkEvent = Analytics.Event.sdk(
                name: "\(Self.self).requiredInputElementTypes",
                params: [
                    "category": "CARD_COMPONENTS",
                    "intent": PrimerInternal.shared.intent?.rawValue ?? "null",
                    "paymentMethodType": paymentMethodType
                ]
            )

            Analytics.Service.record(events: [sdkEvent])

            var mutableRequiredInputElementTypes: [PrimerInputElementType] = [.cardNumber, .expiryDate, .cvv]

            let cardInfoOptions = PrimerAPIConfigurationModule.apiConfiguration?.checkoutModules?
                .filter({ $0.type == "CARD_INFORMATION" })
                .first?.options as? PrimerAPIConfiguration.CheckoutModule.CardInformationOptions

            // swiftlint:disable:next identifier_name
            if let isCardHolderNameCheckoutModuleOptionEnabled = cardInfoOptions?.cardHolderName {
                if isCardHolderNameCheckoutModuleOptionEnabled {
                    mutableRequiredInputElementTypes.append(.cardholderName)
                }
            } else {
                mutableRequiredInputElementTypes.append(.cardholderName)
            }

            return mutableRequiredInputElementTypes
        }
        public var inputElements: [PrimerHeadlessUniversalCheckoutInputElement] = [] {
            didSet {
                let sdkEvent = Analytics.Event.sdk(
                    name: "\(Self.self).inputElements",
                    params: [
                        "category": "CARD_COMPONENTS",
                        "intent": PrimerInternal.shared.intent?.rawValue ?? "null",
                        "paymentMethodType": paymentMethodType
                    ]
                )

                Analytics.Service.record(events: [sdkEvent])

                var tmpInputElementsContainers: [Weak<PrimerInputElementDelegateContainer>] = []
                inputElements.forEach { element in
                    if element.inputElementDelegate != nil {
                        let container = Weak(value: PrimerInputElementDelegateContainer(element: element,
                                                                                        delegate: element.inputElementDelegate))
                        tmpInputElementsContainers.append(container)
                    }
                }
                inputElements.forEach { element in
                    element.inputElementDelegate = self
                }
                originalInputElementsContainers = tmpInputElementsContainers
            }
        }
        private var originalInputElementsContainers: [Weak<PrimerInputElementDelegateContainer>]? = []
        public weak var delegate: PrimerHeadlessUniversalCheckoutCardComponentsManagerDelegate?
        private(set) public var isCardFormValid: Bool = false {
            didSet {
                DispatchQueue.main.async {
                    self.delegate?.cardComponentsManager(self, isCardFormValid: self.isCardFormValid)
                }
            }
        }
        private var resumePaymentId: String?
        private(set) public var paymentMethodTokenData: PrimerPaymentMethodTokenData?
        private(set) public var paymentCheckoutData: PrimerCheckoutData?
        private var webViewController: SFSafariViewController?
        private var webViewCompletion: ((_ authorizationToken: String?, _ error: PrimerError?) -> Void)?

        @available(*, deprecated, message: "CardComponentsManager is no longer supported, please use PrimerHeadlessUniversalCheckout instead")
        public init(paymentMethodType: String) throws {
            let sdkEvent = Analytics.Event.sdk(
                name: "\(Self.self).\(#function)",
                params: [
                    "category": "CARD_COMPONENTS",
                    "intent": PrimerInternal.shared.intent?.rawValue ?? "null",
                    "paymentMethodType": paymentMethodType
                ]
            )

            Analytics.Service.record(events: [sdkEvent])

            guard let availablePaymentMethodTypes = PrimerHeadlessUniversalCheckout.current.listAvailablePaymentMethodsTypes()
            else {
                let err = PrimerError.misconfiguredPaymentMethods(userInfo: .errorUserInfoDictionary(),
                                                                  diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }

            if availablePaymentMethodTypes.filter({ $0 == paymentMethodType }).isEmpty {
                let err = PrimerError.unableToPresentPaymentMethod(paymentMethodType: paymentMethodType,
                                                                   userInfo: .errorUserInfoDictionary(),
                                                                   diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }

            self.paymentMethodType = paymentMethodType
            super.init()
        }

        @available(*, deprecated, message: "Use the default `init(paymentMethodType: String)` for multiple payment method types.")
        public override init() {
            self.paymentMethodType = PrimerPaymentMethodType.paymentCard.rawValue

            let sdkEvent = Analytics.Event.sdk(
                name: "\(Self.self).\(#function)",
                params: [
                    "category": "CARD_COMPONENTS",
                    "intent": PrimerInternal.shared.intent?.rawValue ?? "null",
                    "paymentMethodType": paymentMethodType
                ]
            )

            Analytics.Service.record(events: [sdkEvent])

            super.init()
        }

        public func submit() {
            let sdkEvent = Analytics.Event.sdk(
                name: "\(Self.self).\(#function)",
                params: [
                    "category": "CARD_COMPONENTS",
                    "intent": PrimerInternal.shared.intent?.rawValue ?? "null",
                    "paymentMethodType": paymentMethodType
                ]
            )

            Analytics.Service.record(events: [sdkEvent])

            PrimerDelegateProxy.primerHeadlessUniversalCheckoutUIDidStartPreparation(for: PrimerPaymentMethodType.paymentCard.rawValue)

            firstly {
                PrimerHeadlessUniversalCheckout.current.validateSession()
            }
            .then { () -> Promise<Void> in
                self.validateInputData()
            }
            .then { () -> Promise<Void> in
                self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.paymentMethodType))
            }
            .then { () -> Promise<Request.Body.Tokenization> in
                try self.buildRequestBody()
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
                self.paymentCheckoutData = checkoutData
                if PrimerSettings.current.paymentHandling == .auto, let checkoutData = checkoutData {
                    PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
                }
            }
            .ensure {
                PrimerUIManager.dismissPrimerUI(animated: true)
            }
            .catch { error in
                ErrorHandler.handle(error: error)
                let delegate = PrimerHeadlessUniversalCheckout.current.delegate
                delegate?.primerHeadlessUniversalCheckoutDidFail?(withError: error,
                                                                  checkoutData: self.paymentCheckoutData)
            }
        }

        private func validateInputData() -> Promise<Void> {
            return Promise { seal in
                var errors: [PrimerError] = []
                for inputElementType in self.requiredInputElementTypes {
                    let missingElements = self.inputElements.filter { $0.type == inputElementType }
                    if missingElements.isEmpty {
                        let err = PrimerError.missingPrimerInputElement(inputElementType: inputElementType,
                                                                        userInfo: .errorUserInfoDictionary(),
                                                                        diagnosticsId: UUID().uuidString)
                        errors.append(err)
                    }
                }

                if !errors.isEmpty {
                    let err = PrimerError.underlyingErrors(errors: errors,
                                                           userInfo: .errorUserInfoDictionary(),
                                                           diagnosticsId: UUID().uuidString)
                    seal.reject(err)
                    return
                }

                for inputElement in inputElements where !inputElement.isValid {
                    let err = PrimerError.invalidValue(key: "input-element",
                                                       value: inputElement.type.rawValue,
                                                       userInfo: .errorUserInfoDictionary(),
                                                       diagnosticsId: UUID().uuidString)
                    errors.append(err)
                }

                if !errors.isEmpty {
                    let err = PrimerError.underlyingErrors(errors: errors,
                                                           userInfo: .errorUserInfoDictionary(),
                                                           diagnosticsId: UUID().uuidString)
                    seal.reject(err)
                    return
                }

                seal.fulfill()
            }
        }

        private func buildRequestBody() throws -> Promise<Request.Body.Tokenization> {
            switch self.paymentMethodType {
            case PrimerPaymentMethodType.paymentCard.rawValue:
                return makeCardRequestBody()
            case PrimerPaymentMethodType.adyenBancontactCard.rawValue:
                return makeCardRedirectRequestBody()
            default:
                let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType,
                                                               userInfo: .errorUserInfoDictionary(),
                                                               diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
        }

        private func makeCardRedirectRequestBody() -> Promise<Request.Body.Tokenization> {
            return Promise { seal in

                guard let cardnumberField = inputElements
                        .filter({ $0.type == .cardNumber })
                        .first as? PrimerInputTextField,
                      let expiryDateField = inputElements
                        .filter({ $0.type == .expiryDate })
                        .first as? PrimerInputTextField,
                      let cardholderNameField = inputElements
                        .filter({ $0.type == .cardholderName })
                        .first as? PrimerInputTextField
                else {
                    let err = PrimerError.invalidValue(key: "input-element",
                                                       value: nil,
                                                       userInfo: .errorUserInfoDictionary(),
                                                       diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }

                guard cardnumberField.isValid,
                      expiryDateField.isValid,
                      cardholderNameField.isValid,
                      let cardNumber = cardnumberField.internalText,
                      let expiryDate = expiryDateField.internalText,
                      let cardholderName = cardholderNameField.internalText
                else {
                    let err = PrimerError.invalidValue(key: "input-element",
                                                       value: nil,
                                                       userInfo: .errorUserInfoDictionary(),
                                                       diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }

                let expiryArr = expiryDate.components(separatedBy: expiryDateField.type.delimiter!)
                let currentYearAsString = Date().yearComponentAsString
                let index = currentYearAsString.index(currentYearAsString.startIndex, offsetBy: 2)
                let milleniumAndCenturyOfCurrentYearAsString = currentYearAsString.prefix(upTo: index)

                let expiryMonth = expiryArr[0]
                let expiryYear = "\(milleniumAndCenturyOfCurrentYearAsString)\(expiryArr[1])"

                guard let configId = AppState.current.apiConfiguration?.getConfigId(for: paymentMethodType) else {
                    let err = PrimerError.missingPrimerConfiguration(
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }

                let sanatizedCardNumber = (PrimerInputElementType.cardNumber.clearFormatting(value: cardNumber) as? String)
                let cardOffSessionPaymentInstrument = CardOffSessionPaymentInstrument(paymentMethodConfigId: configId,
                                                                                      paymentMethodType: paymentMethodType,
                                                                                      number: sanatizedCardNumber  ?? cardNumber,
                                                                                      expirationMonth: expiryMonth,
                                                                                      expirationYear: expiryYear,
                                                                                      cardholderName: cardholderName)

                seal.fulfill(Request.Body.Tokenization(paymentInstrument: cardOffSessionPaymentInstrument))
            }
        }

        private func makeCardRequestBody() -> Promise<Request.Body.Tokenization> {
            return Promise { seal in

                guard let cardnumberField = inputElements
                        .filter({ $0.type == .cardNumber })
                        .first as? PrimerInputTextField,
                      let expiryDateField = inputElements
                        .filter({ $0.type == .expiryDate })
                        .first as? PrimerInputTextField,
                      let cvvField = inputElements
                        .filter({ $0.type == .cvv })
                        .first as? PrimerInputTextField
                else {
                    let err = PrimerError.invalidValue(key: "input-element",
                                                       value: nil,
                                                       userInfo: .errorUserInfoDictionary(),
                                                       diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }

                guard cardnumberField.isValid,
                      expiryDateField.isValid,
                      cvvField.isValid,
                      let cardNumber = cardnumberField.internalText,
                      let expiryDate = expiryDateField.internalText,
                      let cvv = cvvField.internalText
                else {
                    let err = PrimerError.invalidValue(key: "input-element",
                                                       value: nil,
                                                       userInfo: .errorUserInfoDictionary(),
                                                       diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }

                let expiryArr = expiryDate.components(separatedBy: expiryDateField.type.delimiter!)
                let currentYearAsString = Date().yearComponentAsString
                let index = currentYearAsString.index(currentYearAsString.startIndex, offsetBy: 2)
                let milleniumAndCenturyOfCurrentYearAsString = currentYearAsString.prefix(upTo: index)

                let expiryMonth = expiryArr[0]
                let expiryYear = "\(milleniumAndCenturyOfCurrentYearAsString)\(expiryArr[1])"

                var cardholderName: String?
                if let cardholderNameField = inputElements
                    .filter({ $0.type == .cardholderName })
                    .first as? PrimerInputTextField {
                    if !cardholderNameField.isValid {
                        let err = PrimerError.invalidValue(key: "cardholder-name",
                                                           value: nil,
                                                           userInfo: .errorUserInfoDictionary(),
                                                           diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                        return
                    }

                    cardholderName = cardholderNameField.internalText
                }

                let sanatizedCardNumber = (PrimerInputElementType.cardNumber.clearFormatting(value: cardNumber) as? String)
                let paymentInstrument = CardPaymentInstrument(
                    number: sanatizedCardNumber ?? cardNumber,
                    cvv: cvv,
                    expirationMonth: expiryMonth,
                    expirationYear: expiryYear,
                    cardholderName: cardholderName)

                seal.fulfill(Request.Body.Tokenization(paymentInstrument: paymentInstrument))
            }
        }

        func startPaymentFlow(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<PrimerCheckoutData?> {
            return Promise { seal in
                firstly {
                    self.startPaymentFlowAndFetchDecodedClientToken(withPaymentMethodTokenData: paymentMethodTokenData)
                }
                .done { decodedJWTToken in
                    if let decodedJWTToken = decodedJWTToken {
                        firstly {
                            self.handleDecodedClientTokenIfNeeded(decodedJWTToken,
                                                                  paymentMethodTokenData: paymentMethodTokenData)
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

        internal func handlePrimerWillCreatePaymentEvent(_ paymentMethodData: PrimerPaymentMethodData)
        -> Promise<Void> {
            return Promise { seal in
                if PrimerInternal.shared.intent == .vault {
                    seal.fulfill()
                } else {
                    let checkoutPaymentMethodType = PrimerCheckoutPaymentMethodType(type: paymentMethodData.type)
                    let checkoutPaymentMethodData = PrimerCheckoutPaymentMethodData(type: checkoutPaymentMethodType)

                    var decisionHandlerHasBeenCalled = false

                    PrimerDelegateProxy.primerWillCreatePaymentWithData(
                        checkoutPaymentMethodData,
                        decisionHandler: { paymentCreationDecision in
                            decisionHandlerHasBeenCalled = true

                            switch paymentCreationDecision.type {
                            case .abort(let errorMessage):
                                let error = PrimerError.merchantError(message: errorMessage ?? "",
                                                                      userInfo: .errorUserInfoDictionary(),
                                                                      diagnosticsId: UUID().uuidString)
                                seal.reject(error)
                            case .continue:
                                seal.fulfill()
                            }
                        })

                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        if !decisionHandlerHasBeenCalled {
                            let message =
                                """
The 'decisionHandler' of 'primerHeadlessUniversalCheckoutWillCreatePaymentWithData' hasn't been called. \
Make sure you call the decision handler otherwise the SDK will hang.
"""
                            self.logger.warn(message: message)
                        }
                    }
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
        func startPaymentFlowAndFetchDecodedClientToken(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<DecodedJWTToken?> {
            return Promise { seal in
                if PrimerSettings.current.paymentHandling == .manual {
                    PrimerDelegateProxy.primerDidTokenizePaymentMethod(paymentMethodTokenData) { resumeDecision in
                        if let resumeDecisionType = resumeDecision.type as? PrimerResumeDecision.DecisionType {
                            switch resumeDecisionType {
                            case .succeed:
                                seal.fulfill(nil)

                            case .continueWithNewClientToken(let newClientToken):
                                let apiConfigurationModule = PrimerAPIConfigurationModule()

                                firstly {
                                    apiConfigurationModule.storeRequiredActionClientToken(newClientToken)
                                }
                                .done {
                                    guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                                        let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                                                 diagnosticsId: UUID().uuidString)
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
                                    let err = PrimerError.merchantError(message: message,
                                                                        userInfo: .errorUserInfoDictionary(),
                                                                        diagnosticsId: UUID().uuidString)
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
                                        let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                                                 diagnosticsId: UUID().uuidString)
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
                            userInfo: .errorUserInfoDictionary(),
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
                            let err = PrimerError.invalidValue(key: "paymentResponse",
                                                               value: nil,
                                                               userInfo: .errorUserInfoDictionary(),
                                                               diagnosticsId: UUID().uuidString)
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
                                    let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                                             diagnosticsId: UUID().uuidString)
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

        func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken,
                                              paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<String?> {
            return Promise { seal in
                if decodedJWTToken.intent == RequiredActionName.threeDSAuthentication.rawValue {
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

                        firstly {
                            PrimerUIManager.prepareRootViewController()
                        }
                        .then { () -> Promise<Void> in
                            self.presentWebRedirectViewControllerWithRedirectUrl(redirectUrl)
                        }
                        .then { () -> Promise<String> in
                            let pollingModule = PollingModule(url: statusUrl)
                            return pollingModule.start()
                        }
                        .done { resumeToken in
                            seal.fulfill(resumeToken)
                        }
                        .ensure {
                            DispatchQueue.main.async { [weak self] in
                                self?.webViewCompletion = nil
                                self?.webViewController?.dismiss(animated: true, completion: { [weak self] in
                                    guard let strongSelf = self else { return }
                                    strongSelf.webViewController = nil
                                    PrimerUIManager.dismissPrimerUI(animated: true)
                                })
                            }
                        }
                        .catch { err in
                            seal.reject(err)
                        }
                    } else {
                        let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                                 diagnosticsId: UUID().uuidString)
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
                            self.webViewCompletion = { (_, err) in
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
                            PrimerInternal.shared.dismiss()
                        }
                        .catch { err in
                            if let primerErr = err as? PrimerError {
                                pollingModule?.cancel(withError: primerErr)
                            } else {
                                let err = PrimerError.underlyingErrors(errors: [err],
                                                                       userInfo: .errorUserInfoDictionary(),
                                                                       diagnosticsId: UUID().uuidString)
                                ErrorHandler.handle(error: err)
                                pollingModule?.cancel(withError: err)
                            }

                            pollingModule = nil
                            seal.reject(err)
                        }

                    } else {
                        let error = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                                   diagnosticsId: UUID().uuidString)
                        seal.reject(error)
                    }

                } else {
                    let err = PrimerError.invalidValue(key: "resumeToken",
                                                       value: nil,
                                                       userInfo: .errorUserInfoDictionary(),
                                                       diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                }
            }
        }

        private func presentWebRedirectViewControllerWithRedirectUrl(_ redirectUrl: URL) -> Promise<Void> {
            return Promise { seal in
                self.webViewController = SFSafariViewController(url: redirectUrl)
                self.webViewController!.delegate = self

                self.webViewCompletion = { (_, err) in
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
                            PrimerUIManager.primerRootViewController?.present(self.webViewController!,
                                                                              animated: true,
                                                                              completion: {
                                                                                DispatchQueue.main.async {
                                                                                    seal.fulfill()
                                                                                }
                                                                              })
                        }
                        .catch { _ in }
                    } else {
                        PrimerUIManager.primerRootViewController?.present(self.webViewController!,
                                                                          animated: true,
                                                                          completion: {
                                                                            DispatchQueue.main.async {
                                                                                seal.fulfill()
                                                                            }
                                                                          })
                    }

                }
            }
        }

        // Create payment with Payment method token

        private func handleCreatePaymentEvent(_ paymentMethodData: String) -> Promise<Response.Body.Payment?> {
            return Promise { seal in
                let createResumePaymentService: CreateResumePaymentServiceProtocol = CreateResumePaymentService()
                let paymentRequest = Request.Body.Payment.Create(token: paymentMethodData)
                createResumePaymentService.createPayment(paymentRequest: paymentRequest) { paymentResponse, error in

                    if let error = error {
                        if let paymentResponse {
                            self.paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
                        }

                        seal.reject(error)

                    } else if let paymentResponse = paymentResponse {
                        if paymentResponse.id == nil {
                            let err = PrimerError.paymentFailed(
                                paymentMethodType: self.paymentMethodType,
                                description: "Failed to create payment",
                                userInfo: .errorUserInfoDictionary(),
                                diagnosticsId: UUID().uuidString)
                            ErrorHandler.handle(error: err)
                            seal.reject(err)

                        } else if paymentResponse.status == .failed {
                            let err = PrimerError.failedToProcessPayment(
                                paymentMethodType: self.paymentMethodType,
                                paymentId: paymentResponse.id ?? "nil",
                                status: paymentResponse.status.rawValue,
                                userInfo: .errorUserInfoDictionary(),
                                diagnosticsId: UUID().uuidString)
                            ErrorHandler.handle(error: err)
                            seal.reject(err)

                        } else {
                            seal.fulfill(paymentResponse)
                        }

                    } else {
                        let err = PrimerError.paymentFailed(
                            paymentMethodType: self.paymentMethodType,
                            description: "Failed to create payment",
                            userInfo: .errorUserInfoDictionary(),
                            diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                    }
                }
            }
        }

        func handleResumeStepsBasedOnSDKSettings(resumeToken: String) -> Promise<PrimerCheckoutData?> {
            return Promise { seal in
                if PrimerSettings.current.paymentHandling == .manual {
                    PrimerDelegateProxy.primerDidResumeWith(resumeToken) { resumeDecision in
                        if let resumeDecisionType = resumeDecision.type as? PrimerResumeDecision.DecisionType {
                            switch resumeDecisionType {
                            case .fail(let message):
                                var merchantErr: Error!
                                if let message = message {
                                    let err = PrimerError.merchantError(message: message,
                                                                        userInfo: .errorUserInfoDictionary(),
                                                                        diagnosticsId: UUID().uuidString)
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
                        let resumePaymentIdError = PrimerError.invalidValue(key: "resumePaymentId",
                                                                            value: "Resume Payment ID not valid",
                                                                            userInfo: .errorUserInfoDictionary(),
                                                                            diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: resumePaymentIdError)
                        seal.reject(resumePaymentIdError)
                        return
                    }

                    firstly {
                        self.handleResumePaymentEvent(resumePaymentId, resumeToken: resumeToken)
                    }
                    .done { paymentResponse -> Void in
                        guard let paymentResponse = paymentResponse else {
                            let err = PrimerError.invalidValue(key: "paymentResponse",
                                                               value: nil,
                                                               userInfo: .errorUserInfoDictionary(),
                                                               diagnosticsId: UUID().uuidString)
                            ErrorHandler.handle(error: err)
                            throw err
                        }

                        let chktDataPayment = PrimerCheckoutDataPayment(from: paymentResponse)
                        self.paymentCheckoutData = PrimerCheckoutData(payment: chktDataPayment)
                        seal.fulfill(self.paymentCheckoutData)
                    }
                    .catch { err in
                        seal.reject(err)
                    }
                }
            }
        }

        // Resume payment with Resume payment ID

        private func handleResumePaymentEvent(_ resumePaymentId: String,
                                              resumeToken: String) -> Promise<Response.Body.Payment?> {

            return Promise { seal in
                let createResumePaymentService: CreateResumePaymentServiceProtocol = CreateResumePaymentService()
                let resumeRequest = Request.Body.Payment.Resume(token: resumeToken)
                createResumePaymentService.resumePaymentWithPaymentId(resumePaymentId,
                                                                      paymentResumeRequest: resumeRequest) { paymentResponse, error in

                    if let error = error {
                        if let paymentResponse {
                            self.paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
                        }

                        seal.reject(error)

                    } else if let paymentResponse = paymentResponse {
                        if paymentResponse.id == nil {
                            let err = PrimerError.paymentFailed(
                                paymentMethodType: self.paymentMethodType,
                                description: "Failed to resume payment",
                                userInfo: .errorUserInfoDictionary(),
                                diagnosticsId: UUID().uuidString)
                            ErrorHandler.handle(error: err)
                            seal.reject(err)

                        } else if paymentResponse.status == .failed {
                            let err = PrimerError.failedToProcessPayment(
                                paymentMethodType: self.paymentMethodType,
                                paymentId: paymentResponse.id ?? "nil",
                                status: paymentResponse.status.rawValue,
                                userInfo: .errorUserInfoDictionary(),
                                diagnosticsId: UUID().uuidString)
                            ErrorHandler.handle(error: err)
                            seal.reject(err)

                        } else {
                            seal.fulfill(paymentResponse)
                        }

                    } else {
                        let err = PrimerError.paymentFailed(
                            paymentMethodType: self.paymentMethodType,
                            description: "Failed to resume payment",
                            userInfo: .errorUserInfoDictionary(),
                            diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                    }
                }
            }
        }

        // MARK: - INPUT ELEMENTS DELEGATE

        public func inputElementShouldFocus(_ sender: PrimerHeadlessUniversalCheckoutInputElement) -> Bool {
            guard let senderTextField = sender as? PrimerInputTextField else { return true }
            guard let inputElementContainer = originalInputElementsContainers?
                    .filter({ ($0.value?.element as? PrimerInputTextField) == senderTextField })
                    .first else { return true }

            if let shouldFocus = inputElementContainer.value?.delegate.inputElementShouldFocus?(sender) {
                return shouldFocus
            } else {
                return true
            }
        }

        public func inputElementDidFocus(_ sender: PrimerHeadlessUniversalCheckoutInputElement) {
            guard let senderTextField = sender as? PrimerInputTextField else { return }
            guard let inputElementContainer = originalInputElementsContainers?
                    .filter({ ($0.value?.element as? PrimerInputTextField) == senderTextField })
                    .first else { return }
            inputElementContainer.value?.delegate.inputElementDidFocus?(sender)
        }

        public func inputElementShouldBlur(_ sender: PrimerHeadlessUniversalCheckoutInputElement) -> Bool {
            guard let senderTextField = sender as? PrimerInputTextField else { return true }
            guard let inputElementContainer = originalInputElementsContainers?
                    .filter({ ($0.value?.element as? PrimerInputTextField) == senderTextField })
                    .first else { return true }

            if let shouldBlur = inputElementContainer.value?.delegate.inputElementShouldBlur?(sender) {
                return shouldBlur
            } else {
                return true
            }
        }

        public func inputElementDidBlur(_ sender: PrimerHeadlessUniversalCheckoutInputElement) {
            guard let senderTextField = sender as? PrimerInputTextField else { return }
            guard let inputElementContainer = originalInputElementsContainers?
                    .filter({ ($0.value?.element as? PrimerInputTextField) == senderTextField })
                    .first else { return }
            inputElementContainer.value?.delegate.inputElementDidBlur?(sender)
        }

        public func inputElementValueDidChange(_ sender: PrimerHeadlessUniversalCheckoutInputElement) {
            guard let senderTextField = sender as? PrimerInputTextField else { return }
            guard let inputElementContainer = originalInputElementsContainers?
                    .filter({ ($0.value?.element as? PrimerInputTextField) == senderTextField })
                    .first else { return }
            inputElementContainer.value?.delegate.inputElementValueDidChange?(sender)
        }

        public func inputElementDidDetectType(_ sender: PrimerHeadlessUniversalCheckoutInputElement, type: Any?) {
            guard let senderTextField = sender as? PrimerInputTextField else { return }
            guard let inputElementContainer = originalInputElementsContainers?
                    .filter({ ($0.value?.element as? PrimerInputTextField) == senderTextField })
                    .first else { return }

            if let cvvTextField = self.inputElements.filter({ $0.type == .cvv }).first as? PrimerInputTextField {
                cvvTextField.detectedValueType = type
            }

            inputElementContainer.value?.delegate.inputElementDidDetectType?(sender, type: type)
        }

        public func inputElementValueIsValid(_ sender: PrimerHeadlessUniversalCheckoutInputElement, isValid: Bool) {
            guard let senderTextField = sender as? PrimerInputTextField else { return }
            guard let inputElementContainer = originalInputElementsContainers?
                    .filter({ ($0.value?.element as? PrimerInputTextField) == senderTextField })
                    .first else { return }
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

@available(*, deprecated, message: "CardComponentsManager is no longer supported, please use PrimerHeadlessUniversalCheckout instead")
extension PrimerHeadlessUniversalCheckout.CardComponentsManager: SFSafariViewControllerDelegate {

    public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        if let webViewCompletion = webViewCompletion {
            // Cancelled
            let err = PrimerError.cancelled(
                paymentMethodType: self.paymentMethodType,
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString)

            ErrorHandler.handle(error: err)
            webViewCompletion(nil, err)
        }

        webViewCompletion = nil
    }
}
// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
// swiftlint:enable type_body_length
// swiftlint:enable file_length
