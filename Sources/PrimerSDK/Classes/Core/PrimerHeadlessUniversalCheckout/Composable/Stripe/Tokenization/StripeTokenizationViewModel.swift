//
//  StripeTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 25.04.2024.
//

// swiftlint:disable type_body_length

import UIKit
import SafariServices

class StripeTokenizationViewModel: PaymentMethodTokenizationViewModel {
    
    // MARK: Variables
    private let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
    private var tokenizationComponent: StripeAchTokenizationComponentProtocol
    private var resumeToken: String?
    
    // MARK: Init
    required init(config: PrimerPaymentMethod) {
        tokenizationComponent = StripeAchTokenizationComponent(paymentMethod: config)
        super.init(config: config)
    }
    
    // MARK: Validate
    override func validate() throws {
        try tokenizationComponent.validate()
    }

    override func performPreTokenizationSteps() -> Promise<Void> {
        let event = Analytics.Event.ui(
            action: .click,
            context: Analytics.Event.Property.Context(
                issuerId: nil,
                paymentMethodType: self.config.type,
                url: nil),
            extra: nil,
            objectType: .button,
            objectId: .select,
            objectClass: "\(Self.self)",
            place: .paymentMethodPopup
        )
        Analytics.Service.record(event: event)

        return Promise { seal in
            firstly {
                self.validateReturningPromise()
            }
            .then { () -> Promise<Void> in
                return self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.config.type))
            }
            .done {
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    override func performTokenizationStep() -> Promise<Void> {
        return Promise { seal in
            PrimerDelegateProxy.primerHeadlessUniversalCheckoutDidStartTokenization(for: self.config.type)

            firstly {
                self.checkouEventsNotifierModule.fireDidStartTokenizationEvent()
            }
            .then { () -> Promise<PrimerPaymentMethodTokenData> in
                return self.tokenizationComponent.tokenize()
            }
            .then { paymentMethodTokenData -> Promise<Void> in
                self.paymentMethodTokenData = paymentMethodTokenData
                return self.checkouEventsNotifierModule.fireDidFinishTokenizationEvent()
            }
            .done {
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    override func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }

    override func presentPaymentMethodUserInterface() -> Promise<Void> {
        return Promise { seal in
            
            seal.fulfill()
        }
    }

    override func awaitUserInput() -> Promise<Void> {
        return Promise { seal in

            firstly { () -> Promise<String> in
                if self.isCancelled {
                    let err = PrimerError.cancelled(paymentMethodType: self.config.type, userInfo: .errorUserInfoDictionary(),
                                                    diagnosticsId: UUID().uuidString)
                    throw err
                }
                
                // This should be a method that is called and return a resume Token.
                return Promise { seal in
                    seal.fulfill("resumeToken")
                }
            }
            .done { resumeToken in
                self.resumeToken = resumeToken
                seal.fulfill()
            }
            .ensure {
                self.didCancel = nil
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    override func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken) -> Promise<String?> {
        return Promise { seal in

            if decodedJWTToken.intent?.contains("NOL_PAY_REDIRECTION") == true {
                if let transactionNo = decodedJWTToken.nolPayTransactionNo,
                   let redirectUrlStr = decodedJWTToken.redirectUrl,
                   let redirectUrl = URL(string: redirectUrlStr),
                   let statusUrlStr = decodedJWTToken.statusUrl,
                   let statusUrl = URL(string: statusUrlStr),
                   decodedJWTToken.intent != nil {

                    DispatchQueue.main.async {
                        PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
                    }


                    firstly {
                        self.presentPaymentMethodUserInterface()
                    }
                    .then { () -> Promise<Void> in
                        return self.awaitUserInput()
                    }
                    .done {
                        seal.fulfill(self.resumeToken)
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
            } else {
                seal.fulfill(nil)
            }
        }
    }
}
// swiftlint:enable type_body_length
