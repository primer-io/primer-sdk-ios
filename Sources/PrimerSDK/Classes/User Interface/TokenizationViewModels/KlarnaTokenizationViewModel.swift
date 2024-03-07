import Foundation
import UIKit

#if canImport(PrimerKlarnaSDK)
import PrimerKlarnaSDK
#endif

class KlarnaTokenizationViewModel: PaymentMethodTokenizationViewModel {

    var willPresentExternalView: (() -> Void)?
    var didPresentExternalView: (() -> Void)?
    var willDismissExternalView: (() -> Void)?
    var didDismissExternalView: (() -> Void)?

    #if canImport(PrimerKlarnaSDK)
    private var klarnaViewController: PrimerKlarnaViewController?
    #endif

    #if DEBUG
    private var demoThirdPartySDKViewController: PrimerThirdPartySDKViewController?
    #endif
    private let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
    private var tokenizationComponent: KlarnaTokenizationComponentProtocol
    private var klarnaPaymentSession: Response.Body.Klarna.PaymentSession?
    private var klarnaCustomerTokenAPIResponse: Response.Body.Klarna.CustomerToken?
    private var klarnaPaymentSessionCompletion: ((_ authorizationToken: String?, _ error: Error?) -> Void)?
    private var authorizationToken: String?
    
    required init(config: PrimerPaymentMethod) {
        tokenizationComponent = KlarnaTokenizationComponent(paymentMethod: config)
        super.init(config: config)
    }

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

        PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: self.uiModule.makeIconImageView(withDimension: 24.0), message: nil)

        return Promise { seal in
            #if canImport(PrimerKlarnaSDK)
            firstly {
                self.validateReturningPromise()
            }
            .then { () -> Promise<Void> in
                let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
                return clientSessionActionsModule.selectPaymentMethodIfNeeded(self.config.type, cardNetwork: nil)
            }
            .then { () -> Promise<Void> in
                return self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.config.type))
            }
            .then { () -> Promise<Response.Body.Klarna.PaymentSession> in
                return self.tokenizationComponent.createPaymentSession()
            }
            .then { session -> Promise<Void> in
                self.klarnaPaymentSession = session
                return self.presentPaymentMethodUserInterface()
            }
            .then { () -> Promise<Void> in
                return self.awaitUserInput()
            }
            .then { () -> Promise<Response.Body.Klarna.CustomerToken> in
                return self.tokenizationComponent.authorizePaymentSession(authorizationToken: self.authorizationToken!)
            }
            .done { klarnaCustomerTokenAPIResponse in
                self.klarnaCustomerTokenAPIResponse = klarnaCustomerTokenAPIResponse
                DispatchQueue.main.async {
                    self.willDismissExternalView?()
                }

                seal.fulfill()
            }
            .ensure {
                self.willDismissExternalView?()
                self.klarnaViewController?.dismiss(animated: true, completion: {
                    self.didDismissExternalView?()
                })

                #if DEBUG
                self.demoThirdPartySDKViewController?.dismiss(animated: true, completion: {
                    self.didDismissExternalView?()
                })
                #endif
            }
            .catch { err in
                seal.reject(err)
            }
            #else
            let error = KlarnaHelpers.getMissingSDKError()
            ErrorHandler.handle(error: error)
            seal.reject(error)
            #endif
        }
    }

    override func performTokenizationStep() -> Promise<Void> {
        return Promise { seal in
            firstly {
                self.checkouEventsNotifierModule.fireDidStartTokenizationEvent()
            }
            .then { () -> Promise<PrimerPaymentMethodTokenData> in
                let customerToken = self.klarnaCustomerTokenAPIResponse
                return self.tokenizationComponent.tokenizeDropIn(customerToken: customerToken, offSessionAuthorizationId: self.authorizationToken!)
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
            DispatchQueue.main.async {
                var isMockedBE = false
                #if DEBUG
                if PrimerAPIConfiguration.current?.clientSession?.testId != nil {
                    isMockedBE = true
                }
                #endif

                if !isMockedBE {
                    #if canImport(PrimerKlarnaSDK)
                    guard let urlSchemeStr = self.settings.paymentMethodOptions.urlScheme,
                          URL(string: urlSchemeStr) != nil else {
                        let error = KlarnaHelpers.getInvalidUrlSchemeError(settings: self.settings)
                        seal.reject(error)
                        return
                    }

                    // Here, PrimerKlarnaViewController should be loaded with both categories.
                    // PrimerKlarnaViewController need to be refactred and updated to suport 'category pick'.
                    self.klarnaViewController = PrimerKlarnaViewController(
                        delegate: self,
                        paymentCategory: .payNow,
                        clientToken: self.klarnaPaymentSession!.clientToken,
                        urlScheme: urlSchemeStr)

                    self.klarnaPaymentSessionCompletion = { _, err in
                        if let err = err {
                            seal.reject(err)
                        } else {
                            fatalError()
                        }
                    }

                    self.willPresentExternalView?()
                    PrimerUIManager.primerRootViewController?.show(viewController: self.klarnaViewController!)
                    self.didPresentExternalView?()
                    seal.fulfill()
                    #else
                    seal.fulfill()
                    #endif
                } else {
                    #if DEBUG
                    firstly {
                        PrimerUIManager.prepareRootViewController()
                    }
                    .done {
                        self.demoThirdPartySDKViewController = PrimerThirdPartySDKViewController(paymentMethodType: self.config.type)
                        self.demoThirdPartySDKViewController!.onSendCredentialsButtonTapped = {
                            self.klarnaPaymentSessionCompletion?("mock_auth_token", nil)
                        }
                        PrimerUIManager.primerRootViewController?.present(self.demoThirdPartySDKViewController!, animated: true, completion: {
                            seal.fulfill()
                        })
                    }
                    .catch { _ in
                        seal.fulfill()
                    }
                    #endif
                }
            }
        }
    }

    override func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
            self.klarnaPaymentSessionCompletion = { authorizationToken, err in
                if let err = err {
                    seal.reject(err)
                } else if let authorizationToken = authorizationToken {
                    self.authorizationToken = authorizationToken
                    seal.fulfill()
                } else {
                    precondition(false, "Should never end up in here")
                }
            }
        }
    }
}

#if canImport(PrimerKlarnaSDK)
extension KlarnaTokenizationViewModel: PrimerKlarnaViewControllerDelegate {

    func primerKlarnaViewDidLoad() { }

    func primerKlarnaPaymentSessionCompleted(authorizationToken: String?, error: PrimerKlarnaError?) {
        self.klarnaPaymentSessionCompletion?(authorizationToken, error)
        self.klarnaPaymentSessionCompletion = nil
    }
}
#endif
