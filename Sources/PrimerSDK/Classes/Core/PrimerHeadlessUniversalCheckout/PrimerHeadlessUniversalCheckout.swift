//
//  PrimerHeadlessUniversalCheckout.swift
//  PrimerSDK
//
//  Created by Evangelos on 28/1/22.
//

import UIKit

public class PrimerHeadlessUniversalCheckout: LogReporter {

    public static let current = PrimerHeadlessUniversalCheckout()

    public weak var delegate: PrimerHeadlessUniversalCheckoutDelegate? {
        didSet {
            PrimerInternal.shared.sdkIntegrationType = .headless
        }
    }
    public weak var uiDelegate: PrimerHeadlessUniversalCheckoutUIDelegate? {
        didSet {
            PrimerInternal.shared.sdkIntegrationType = .headless
        }
    }
    private(set) public var clientToken: String?

    internal let sdkSessionId = UUID().uuidString
    internal private(set) var checkoutSessionId: String?
    internal private(set) var timingEventId: String?

    private var apiConfigurationModule: PrimerAPIConfigurationModuleProtocol = PrimerAPIConfigurationModule()
    private let unsupportedPaymentMethodTypes: [String] = [
        PrimerPaymentMethodType.adyenBlik.rawValue,
        PrimerPaymentMethodType.adyenDotPay.rawValue,
        PrimerPaymentMethodType.adyenIDeal.rawValue,
        PrimerPaymentMethodType.goCardless.rawValue,
        PrimerPaymentMethodType.googlePay.rawValue,
        PrimerPaymentMethodType.primerTestKlarna.rawValue,
        PrimerPaymentMethodType.primerTestPayPal.rawValue,
        PrimerPaymentMethodType.primerTestSofort.rawValue,
        PrimerPaymentMethodType.xfersPayNow.rawValue
    ]

    fileprivate init() {
        Analytics.Service.flush()
    }

    public func start(
        withClientToken clientToken: String,
        settings: PrimerSettings? = nil,
        delegate: PrimerHeadlessUniversalCheckoutDelegate? = nil,
        uiDelegate: PrimerHeadlessUniversalCheckoutUIDelegate? = nil,
        completion: @escaping (_ paymentMethods: [PrimerHeadlessUniversalCheckout.PaymentMethod]?, _ err: Error?) -> Void
    ) {
        PrimerInternal.shared.sdkIntegrationType = .headless
        PrimerInternal.shared.intent = .checkout

        DependencyContainer.register(settings ?? PrimerSettings() as PrimerSettingsProtocol)

        if delegate != nil {
            PrimerHeadlessUniversalCheckout.current.delegate = delegate
        }

        if PrimerHeadlessUniversalCheckout.current.delegate == nil {
            logger.warn(message: "PrimerHeadlessUniversalCheckout delegate has not been set, and you won't be able to receive the Payment Method Token data to create a payment.")
        }

        PrimerInternal.shared.checkoutSessionId = UUID().uuidString
        PrimerInternal.shared.timingEventId = UUID().uuidString

        var events: [Analytics.Event] = []

        let sdkEvent = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: "\(Self.self).\(#function)",
                params: [
                    "intent": PrimerInternal.shared.intent?.rawValue ?? "null"
                ]))

        let connectivityEvent = Analytics.Event(
            eventType: .networkConnectivity,
            properties: NetworkConnectivityEventProperties(
                networkType: Connectivity.networkType))

        let timingStartEvent = Analytics.Event(
            eventType: .timerEvent,
            properties: TimerEventProperties(
                momentType: .start,
                id: PrimerInternal.shared.timingEventId!))

        events = [sdkEvent, connectivityEvent, timingStartEvent]
        Analytics.Service.record(events: events)

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
                let err = PrimerError.misconfiguredPaymentMethods(userInfo: ["file": #file,
                                                                             "class": "\(Self.self)",
                                                                             "function": #function,
                                                                             "line": "\(#line)"],
                                                                  diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                DispatchQueue.main.async {
                    completion(nil, err)
                }
            } else {
                DispatchQueue.main.async {
                    let availablePaymentMethods = PrimerHeadlessUniversalCheckout.PaymentMethod.availablePaymentMethods
                    PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidLoadAvailablePaymentMethods?(availablePaymentMethods)
                    completion(availablePaymentMethods, nil)
                }
            }
        }
        .catch { err in
            DispatchQueue.main.async {
                completion(nil, err)
            }
        }
    }

    public func cleanUp() {
        PrimerAPIConfigurationModule.resetSession()
    }

    // MARK: - HELPERS

    private func continueValidateSession() -> Promise<Void> {
        return Promise { seal in
            guard let clientToken = PrimerAPIConfigurationModule.clientToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)", "reason": "Client token is nil"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            guard let decodedJWTToken = clientToken.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)", "reason": "Client token cannot be decoded"], diagnosticsId: UUID().uuidString)
                seal.reject(err)
                return
            }

            do {
                try decodedJWTToken.validate()
            } catch {
                seal.reject(error)
            }

            guard let apiConfiguration = PrimerAPIConfigurationModule.apiConfiguration else {
                let err = PrimerError.missingPrimerConfiguration(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                seal.reject(err)
                return
            }

            guard let paymentMethods = apiConfiguration.paymentMethods, !paymentMethods.isEmpty else {
                let err = PrimerError.misconfiguredPaymentMethods(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                seal.reject(err)
                return
            }

            seal.fulfill()
        }
    }

    internal func validateSession() -> Promise<Void> {
        return Promise { seal in
            guard let clientToken = PrimerAPIConfigurationModule.clientToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)", "reason": "Client token is nil"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            guard let decodedJWTToken = clientToken.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)", "reason": "Client token cannot be decoded"], diagnosticsId: UUID().uuidString)
                seal.reject(err)
                return
            }

            do {
                try decodedJWTToken.validate()
            } catch {
                seal.reject(error)
            }

            guard let apiConfiguration = PrimerAPIConfigurationModule.apiConfiguration else {
                let err = PrimerError.missingPrimerConfiguration(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                seal.reject(err)
                return
            }

            guard let paymentMethods = apiConfiguration.paymentMethods, !paymentMethods.isEmpty else {
                let err = PrimerError.misconfiguredPaymentMethods(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
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
            logger.warn(message: "Klarna configuration has been found but module 'PrimerKlarnaSDK' is missing. Add `PrimerKlarnaSDK' in your project by adding \"pod 'PrimerKlarnaSDK'\" in your podfile or by adding \"primer-klarna-sdk-ios\" in your Swift Package Manager, so you can perform payments with Klarna.")
        }
#endif

#if !canImport(PrimerIPay88MYSDK)
        if let iPay88ViewModelIndex = paymentMethods?.firstIndex(where: { $0.type == PrimerPaymentMethodType.iPay88Card.rawValue }) {
            paymentMethods?.remove(at: iPay88ViewModelIndex)
            logger.warn(message: "iPay88 configuration has been found but module 'PrimerIPay88SDK' is missing. Add `PrimerIPay88SDK' in your project by adding \"pod 'PrimerIPay88SDK'\" in your podfile, so you can perform payments with iPay88.")
        }
#endif

#if !canImport(PrimerNolPaySDK)
        if let nolPayViewModelIndex = paymentMethods?.firstIndex(where: { $0.type == PrimerPaymentMethodType.nolPay.rawValue }) {
            paymentMethods?.remove(at: nolPayViewModelIndex)
            logger.warn(message: "NolPay configuration has been found but module 'PrimerNolPaySDK' is missing. Add `PrimerNolPaySDK' in your project by adding \"pod 'PrimerNolPaySDK'\" in your podfile, so you can perform payments with NolPay.")
        }
#endif

        return paymentMethods?.compactMap({ $0.type }).filter({ !unsupportedPaymentMethodTypes.contains($0) })
    }
}
