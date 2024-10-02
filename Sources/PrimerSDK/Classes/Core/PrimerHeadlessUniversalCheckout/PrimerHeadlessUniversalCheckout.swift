//
//  PrimerHeadlessUniversalCheckout.swift
//  PrimerSDK
//
//  Created by Evangelos on 28/1/22.
//

// swiftlint:disable function_body_length
// swiftlint:disable type_body_length

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
        let start = Date().millisecondsSince1970

        PrimerInternal.shared.sdkIntegrationType = .headless
        PrimerInternal.shared.intent = .checkout

        DependencyContainer.register(settings ?? PrimerSettings() as PrimerSettingsProtocol)

        if delegate != nil {
            PrimerHeadlessUniversalCheckout.current.delegate = delegate
        }

        if uiDelegate != nil {
            PrimerHeadlessUniversalCheckout.current.uiDelegate = uiDelegate
        }

        if PrimerHeadlessUniversalCheckout.current.delegate == nil {
            let message = """
                PrimerHeadlessUniversalCheckout delegate has not been set, \
                and you won't be able to receive the Payment Method Token \
                data to create a payment."
                """
            logger.warn(message: message)
        }

        PrimerInternal.shared.checkoutSessionId = UUID().uuidString
        PrimerInternal.shared.timingEventId = UUID().uuidString

        var events: [Analytics.Event] = []

        let sdkEvent = Analytics.Event.sdk(
            name: "\(Self.self).\(#function)",
            params: [ "intent": PrimerInternal.shared.intent?.rawValue ?? "null" ]
        )

        let connectivityEvent = Analytics.Event.networkConnectivity(networkType: Connectivity.networkType)

        let timingStartEvent = Analytics.Event.timer(
            momentType: .start,
            id: PrimerInternal.shared.timingEventId ?? "Unknown"
        )

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
            let currencyLoader = CurrencyLoader(storage: DefaultCurrencyStorage(), networkService: CurrencyNetworkService())
            currencyLoader.updateCurrenciesFromAPI()
            let availablePaymentMethodsTypes = PrimerHeadlessUniversalCheckout.current.listAvailablePaymentMethodsTypes()
            if (availablePaymentMethodsTypes ?? []).isEmpty {
                let err = PrimerError.misconfiguredPaymentMethods(userInfo: .errorUserInfoDictionary(),
                                                                  diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                DispatchQueue.main.async {
                    completion(nil, err)
                }
            } else {
                DispatchQueue.main.async {
                    let availablePaymentMethods = PrimerHeadlessUniversalCheckout.PaymentMethod.availablePaymentMethods
                    let delegate = PrimerHeadlessUniversalCheckout.current.delegate
                    delegate?.primerHeadlessUniversalCheckoutDidLoadAvailablePaymentMethods?(availablePaymentMethods)
                    self.recordLoadedEvent(start)
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

    private func recordLoadedEvent(_ start: Int) {
        let end = Date().millisecondsSince1970
        let interval = end - start
        let showEvent = Analytics.Event.headlessLoading(duration: interval)
        Analytics.Service.record(events: [showEvent])
    }

    public func cleanUp() {
        Self.queue.sync(flags: .barrier) {
            PrimerAPIConfigurationModule.resetSession()
            ConfigurationCache.shared.clearCache()
            PrimerInternal.shared.checkoutSessionId = nil
        }
    }

    // MARK: - HELPERS

    private func continueValidateSession() -> Promise<Void> {
        return Promise { seal in
            guard let clientToken = PrimerAPIConfigurationModule.clientToken else {
                let info = ["reason": "Client token is nil"]
                let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(additionalInfo: info),
                                                         diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            guard let decodedJWTToken = clientToken.decodedJWTToken else {
                let info = ["reason": "Client token cannot be decoded"]
                let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(additionalInfo: info),
                                                         diagnosticsId: UUID().uuidString)
                seal.reject(err)
                return
            }

            do {
                try decodedJWTToken.validate()
            } catch {
                seal.reject(error)
            }

            guard let apiConfiguration = PrimerAPIConfigurationModule.apiConfiguration else {
                let err = PrimerError.missingPrimerConfiguration(userInfo: .errorUserInfoDictionary(),
                                                                 diagnosticsId: UUID().uuidString)
                seal.reject(err)
                return
            }

            guard let paymentMethods = apiConfiguration.paymentMethods, !paymentMethods.isEmpty else {
                let err = PrimerError.misconfiguredPaymentMethods(userInfo: .errorUserInfoDictionary(),
                                                                  diagnosticsId: UUID().uuidString)
                seal.reject(err)
                return
            }

            seal.fulfill()
        }
    }

    internal func validateSession() -> Promise<Void> {
        return Promise { seal in
            guard let clientToken = PrimerAPIConfigurationModule.clientToken else {
                let info = ["reason": "Client token is nil"]
                let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(additionalInfo: info),
                                                         diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            guard let decodedJWTToken = clientToken.decodedJWTToken else {
                let info = ["reason": "Client token cannot be decoded"]
                let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(additionalInfo: info),
                                                         diagnosticsId: UUID().uuidString)
                seal.reject(err)
                return
            }

            do {
                try decodedJWTToken.validate()
            } catch {
                seal.reject(error)
            }

            guard let apiConfiguration = PrimerAPIConfigurationModule.apiConfiguration else {
                let err = PrimerError.missingPrimerConfiguration(userInfo: .errorUserInfoDictionary(),
                                                                 diagnosticsId: UUID().uuidString)
                seal.reject(err)
                return
            }

            guard let paymentMethods = apiConfiguration.paymentMethods, !paymentMethods.isEmpty else {
                let err = PrimerError.misconfiguredPaymentMethods(userInfo: .errorUserInfoDictionary(),
                                                                  diagnosticsId: UUID().uuidString)
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
            let message =
                """
Klarna configuration has been found but module 'PrimerKlarnaSDK' is missing. \
Add `PrimerKlarnaSDK' in your project by adding \"pod 'PrimerKlarnaSDK'\" in your Podfile, \
or by adding \"primer-klarna-sdk-ios\" in your Swift Package Manager
"""
            logger.warn(message: message)
        }
        #endif

        #if !canImport(PrimerIPay88MYSDK)
        if let iPay88ViewModelIndex = paymentMethods?.firstIndex(where: { $0.type == PrimerPaymentMethodType.iPay88Card.rawValue }) {
            paymentMethods?.remove(at: iPay88ViewModelIndex)
            let message =
                """
iPay88 configuration has been found but module 'PrimerIPay88SDK' is missing. \
Add `PrimerIPay88SDK' in your project by adding \"pod 'PrimerIPay88SDK'\" in your Podfile.
"""
            logger.warn(message: message)
        }
        #endif

        #if !canImport(PrimerNolPaySDK)
        if let nolPayViewModelIndex = paymentMethods?.firstIndex(where: { $0.type == PrimerPaymentMethodType.nolPay.rawValue }) {
            paymentMethods?.remove(at: nolPayViewModelIndex)
            let message =
                """
NolPay configuration has been found but module 'PrimerNolPaySDK' is missing. \
Add `PrimerNolPaySDK' in your project by adding \"pod 'PrimerNolPaySDK'\" in your Podfile.
"""
            logger.warn(message: message)
        }
        #endif

        return paymentMethods?.compactMap({ $0.type }).filter({ !unsupportedPaymentMethodTypes.contains($0) })
    }

    private static let queue: DispatchQueue = DispatchQueue(label: "primer.headlessUniversalCheckout", qos: .default)
}
// swiftlint:enable function_body_length
// swiftlint:enable type_body_length
