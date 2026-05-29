//
//  AnalyticsEvent.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation

// swiftlint:disable all
extension Analytics {
    struct Event: Codable, Equatable {

        static func == (lhs: Analytics.Event, rhs: Analytics.Event) -> Bool {
            lhs.localId == rhs.localId
        }

        let analyticsUrl: String?
        let localId: String
        let appIdentifier: String?
        let checkoutSessionId: String?
        let clientSessionId: String?
        var createdAt: Int  // 👈 `createdAt` will be modified and get the error's timestamp for error events.
        let customerId: String?
        let device: Device
        let eventType: Analytics.Event.EventType
        let primerAccountId: String?
        var properties: AnalyticsEventProperties?  // 👈 `properties` can be modified.
        let sdkSessionId: String
        let sdkType: String
        let sdkVersion: String?
        let sdkIntegrationType: PrimerSDKIntegrationType?
        let sdkPaymentHandling: PrimerPaymentHandling?
        let integrationType: String
        let minDeploymentTarget: String

        init(
            eventType: Analytics.Event.EventType,
            properties: AnalyticsEventProperties?,
            analyticsUrl: String? = PrimerAPIConfigurationModule.decodedJWTToken?.analyticsUrlV2
        ) {
            self.analyticsUrl = analyticsUrl
            self.localId = String.randomString(length: 32)

            self.appIdentifier = Bundle.main.bundleIdentifier
            self.checkoutSessionId = PrimerInternal.shared.checkoutSessionId
            self.clientSessionId = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.clientSessionId
            self.createdAt = Date().millisecondsSince1970
            self.customerId = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.customer?.id
            self.device = Device()
            self.eventType = eventType
            self.primerAccountId = PrimerAPIConfigurationModule.apiConfiguration?.primerAccountId
            self.properties = properties
            self.sdkSessionId = PrimerInternal.shared.sdkSessionId
            self.sdkType = Primer.shared.integrationOptions?.reactNativeVersion == nil ? "IOS_NATIVE" : "RN_IOS"
            self.sdkVersion = VersionUtils.releaseVersionNumber
            self.sdkIntegrationType = PrimerInternal.shared.sdkIntegrationType
            self.sdkPaymentHandling = PrimerSettings.current.paymentHandling
            self.minDeploymentTarget = Bundle.main.minimumOSVersion ?? "Unknown"

            #if COCOAPODS
                self.integrationType = "COCOAPODS"
            #else
                self.integrationType = "SPM"
            #endif
        }

        private enum CodingKeys: String, CodingKey {
            case analyticsUrl,
                 localId,
                 appIdentifier,
                 checkoutSessionId,
                 clientSessionId,
                 createdAt,
                 customerId,
                 device,
                 eventType,
                 primerAccountId,
                 properties,
                 sdkSessionId,
                 sdkType,
                 sdkVersion,
                 sdkIntegrationType,
                 sdkPaymentHandling,
                 integrationType,
                 minDeploymentTarget
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try? container.encode(analyticsUrl, forKey: .analyticsUrl)
            try? container.encode(appIdentifier, forKey: .appIdentifier)
            try? container.encode(checkoutSessionId, forKey: .checkoutSessionId)
            try? container.encode(clientSessionId, forKey: .clientSessionId)
            try? container.encode(createdAt, forKey: .createdAt)
            try? container.encode(customerId, forKey: .customerId)
            try? container.encode(device, forKey: .device)
            try? container.encode(eventType, forKey: .eventType)
            try? container.encode(localId, forKey: .localId)
            try? container.encode(primerAccountId, forKey: .primerAccountId)
            try? container.encode(sdkSessionId, forKey: .sdkSessionId)
            try? container.encode(sdkType, forKey: .sdkType)
            try? container.encode(sdkVersion, forKey: .sdkVersion)
            try? container.encode(sdkIntegrationType?.rawValue, forKey: .sdkIntegrationType)
            try? container.encode(integrationType, forKey: .integrationType)
            try? container.encode(minDeploymentTarget, forKey: .minDeploymentTarget)

            if sdkPaymentHandling == .auto {
                try? container.encode("AUTO", forKey: .sdkPaymentHandling)
            } else if sdkPaymentHandling == .manual {
                try? container.encode("MANUAL", forKey: .sdkPaymentHandling)
            }

            if let messageEventProperties = properties as? MessageEventProperties {
                try? container.encode(messageEventProperties, forKey: .properties)
            } else if let networkCallEventProperties = properties as? NetworkCallEventProperties {
                try? container.encode(networkCallEventProperties, forKey: .properties)
            } else if let networkConnectivityEventProperties = properties as? NetworkConnectivityEventProperties {
                try? container.encode(networkConnectivityEventProperties, forKey: .properties)
            } else if let sdkEventProperties = properties as? SDKEventProperties {
                try? container.encode(sdkEventProperties, forKey: .properties)
            } else if let appLifecycleEventProperties = properties as? AppLifecycleEventProperties {
                try? container.encode(appLifecycleEventProperties, forKey: .properties)
            } else if let timerEventProperties = properties as? TimerEventProperties {
                try? container.encode(timerEventProperties, forKey: .properties)
            } else if let uiEventProperties = properties as? UIEventProperties {
                try? container.encode(uiEventProperties, forKey: .properties)
            } else if let rawEventProperties = properties as? RawEventProperties {
                try? container.encode(rawEventProperties, forKey: .properties)
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.analyticsUrl = try container.decodeIfPresent(String.self, forKey: .analyticsUrl)
            self.appIdentifier = try container.decodeIfPresent(String.self, forKey: .appIdentifier)
            self.checkoutSessionId = try container.decodeIfPresent(String.self, forKey: .checkoutSessionId)
            self.clientSessionId = try container.decodeIfPresent(String.self, forKey: .clientSessionId)
            self.createdAt = try container.decode(Int.self, forKey: .createdAt)
            self.customerId = try container.decodeIfPresent(String.self, forKey: .customerId)
            self.device = try container.decode(Device.self, forKey: .device)
            self.eventType = try container.decode(Analytics.Event.EventType.self, forKey: .eventType)
            self.localId = try container.decode(String.self, forKey: .localId)
            self.primerAccountId = try container.decodeIfPresent(String.self, forKey: .primerAccountId)
            self.sdkSessionId = try container.decode(String.self, forKey: .sdkSessionId)
            self.sdkType = try container.decode(String.self, forKey: .sdkType)
            self.sdkVersion = try container.decode(String.self, forKey: .sdkVersion)
            self.integrationType = try container.decode(String.self, forKey: .integrationType)
            self.minDeploymentTarget = try container.decode(String.self, forKey: .minDeploymentTarget)

            if let sdkIntegrationTypeStr = try? container.decode(String.self, forKey: .sdkIntegrationType) {
                self.sdkIntegrationType = PrimerSDKIntegrationType(rawValue: sdkIntegrationTypeStr)
            } else {
                self.sdkIntegrationType = nil
            }

            if let sdkPaymentHandlingStr = try? container.decode(String.self, forKey: .sdkPaymentHandling) {
                if sdkPaymentHandlingStr == "AUTO" {
                    self.sdkPaymentHandling = .auto
                } else if sdkPaymentHandlingStr == "MANUAL" {
                    self.sdkPaymentHandling = .manual
                } else {
                    self.sdkPaymentHandling = nil
                }
            } else {
                self.sdkPaymentHandling = nil
            }

            if let messageEventProperties = (try? container.decode(MessageEventProperties?.self, forKey: .properties)) {
                self.properties = messageEventProperties
            } else if let networkCallEventProperties = (try? container.decode(NetworkCallEventProperties?.self, forKey: .properties)) {
                self.properties = networkCallEventProperties
            } else if let networkConnectivityEventProperties = (try? container.decode(NetworkConnectivityEventProperties?.self, forKey: .properties)) {
                self.properties = networkConnectivityEventProperties
            } else if let sdkEventProperties = (try? container.decode(SDKEventProperties?.self, forKey: .properties)) {
                self.properties = sdkEventProperties
            } else if let appLifecycleEventProperties = (try? container.decode(AppLifecycleEventProperties?.self, forKey: .properties)) {
                self.properties = appLifecycleEventProperties
            } else if let timerEventProperties = (try? container.decode(TimerEventProperties?.self, forKey: .properties)) {
                self.properties = timerEventProperties
            } else if let uiEventProperties = (try? container.decode(UIEventProperties?.self, forKey: .properties)) {
                self.properties = uiEventProperties
            } else {
                self.properties = try? container.decode(RawEventProperties.self, forKey: .properties)
            }
        }
    }
}

extension Analytics.Event {

    struct EventType: RawRepresentable, Codable, Equatable {
        let rawValue: String

        static let ui                             = EventType(rawValue: "UI_EVENT")
        static let crash                          = EventType(rawValue: "APP_CRASHED_EVENT")
        static let message                        = EventType(rawValue: "MESSAGE_EVENT")
        static let networkCall                    = EventType(rawValue: "NETWORK_CALL_EVENT")
        static let networkConnectivity            = EventType(rawValue: "NETWORK_CONNECTIVITY_EVENT")
        static let sdkEvent                       = EventType(rawValue: "SDK_FUNCTION_EVENT")
        static let timerEvent                     = EventType(rawValue: "TIMER_EVENT")
        static let appLifecycle                   = EventType(rawValue: "APP_LIFECYCLE_EVENT")
        static let paymentMethodImageLoading      = EventType(rawValue: "PM_IMAGE_LOADING_DURATION")
        static let paymentMethodAllImagesLoading  = EventType(rawValue: "PM_ALL_IMAGES_LOADING_DURATION")
    }

    struct Property {
        enum Action: String, Codable {
            case blur       = "BLUR"
            case click      = "CLICK"
            case focus      = "FOCUS"
            case view       = "VIEW"
            case present    = "PRESENT"
            case dismiss    = "DISMISS"
        }

        struct Context: Codable {

            var issuerId: String?
            var paymentMethodType: String?
            var cardNetworks: [String]?
            var url: String?
            var iPay88PaymentMethodId: String?
            var iPay88ActionType: String?

            init(
                issuerId: String? = nil,
                paymentMethodType: String? = nil,
                cardNetworks: [String]? = nil,
                url: String? = nil,
                iPay88PaymentMethodId: String? = nil,
                iPay88ActionType: String? = nil
            ) {
                self.issuerId = issuerId
                self.paymentMethodType = paymentMethodType
                self.cardNetworks = cardNetworks
                self.url = url
                self.iPay88PaymentMethodId = iPay88PaymentMethodId
                self.iPay88ActionType = iPay88ActionType
            }
        }

        enum MessageType: String, Codable {
            case error                              = "ERROR"
            case missingValue                       = "MISSING_VALUE"
            case paymentMethodImageLoadingFailed    = "PM_IMAGE_LOADING_FAILED"
            case validationFailed                   = "VALIDATION_FAILED"
            case info                               = "INFO"
            case other                              = "OTHER"
            case retry                              = "RETRY"
            case retryFailed                        = "RETRY_FAILED"
            case retrySuccess                       = "RETRY_SUCCESS"
            case backendDrivenCheckoutStarted       = "BDC_FLOW_START"
        }

        enum TimerType: String, Codable {
            case start  = "START"
            case end    = "END"
        }

        enum NetworkCallType: String, Codable {
            case requestStart   = "REQUEST_START"
            case requestEnd     = "REQUEST_END"
        }

        enum ObjectType: String, Codable {
            case alert          = "ALERT"
            case button         = "BUTTON"
            case image          = "IMAGE"
            case input          = "INPUT"
            case label          = "LABEL"
            case list           = "LIST"
            case listItem       = "LIST_ITEM"
            case loader         = "LOADER"
            case view           = "VIEW"
            case webpage        = "WEB_PAGE"
            case thirdPartyView = "3RD_PARTY_VIEW"
        }

        enum ObjectId: String, Codable {
            case back                       = "BACK"
            case cancel                     = "CANCEL"
            case cardHolder                 = "CARD_HOLDER"
            case cardNumber                 = "CARD_NUMBER"
            case cardNetwork                = "CARD_NETWORK"
            case cvc                        = "CVC"
            case delete                     = "DELETE"
            case done                       = "DONE"
            case edit                       = "EDIT"
            case expiry                     = "EXPIRY"
            case ibank                      = "IBAN"
            case otp                        = "OTP"
            case seeAll                     = "SEE_ALL"
            case select                     = "SELECT"
            case pay                        = "PAY"
            case phone                      = "PHONE"
            case retry                      = "RETRY"
            case submit                     = "SUBMIT"
            case billingAddressPostalCode   = "BILLING_ADDRESS_POSTAL_CODE"
            case billingAddressFirstName    = "BILLING_ADDRESS_FIRST_NAME"
            case billingAddressLastName     = "BILLING_ADDRESS_LAST_NAME"
            case billingAddressLine1        = "BILLING_ADDRESS_LINE_1"
            case billingAddressLine2        = "BILLING_ADDRESS_LINE_2"
            case billingAddressCity         = "BILLING_ADDRESS_CITY"
            case billingAddressState        = "BILLING_ADDRESS_STATE"
            case billingAddressCountry      = "BILLING_ADDRESS_COUNTRY"
        }

        enum Place: String, Codable {
            case bankSelectionList      = "BANK_SELECTION_LIST"
            case countrySelectionList   = "COUNTRY_SELECTION_LIST"
            case retailSelectionList    = "RETAIL_SELECTION_LIST"
            case cardForm               = "CARD_FORM"
            case directCheckout         = "DIRECT_CHECKOUT"
            case dynamicForm            = "DYNAMIC_FORM"
            case errorScreen            = "ERROR_SCREEN"
            case paymentMethodsList     = "PAYMENT_METHODS_LIST"
            case paymentMethodLoading   = "PAYMENT_METHOD_LOADING"
            case paymentMethodPopup     = "PAYMENT_METHOD_POPUP"
            case sdkLoading             = "SDK_LOADING"
            case successScreen          = "SUCCESS_SCREEN"
            case vaultManager           = "VAULT_MANAGER"
            case webview                = "WEBVIEW"
            case universalCheckout      = "UNIVERSAL_CHECKOUT"
            case threeDSScreen          = "3DS_VIEW"
            case iPay88View             = "IPAY88_VIEW"
            case cvvRecapture           = "CVV_RECAPTURE"
            case navigationBar          = "PRIMER_NAV_BAR"
        }

        enum Severity: String, Codable {
            case debug      = "DEBUG"
            case info       = "INFO"
            case warning    = "WARNING"
            case error      = "ERROR"
        }
    }

}

extension Analytics.Event {

    static func sdk(name: String, params: [String: String]?) -> Self {
        .init(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: name,
                params: params
            )
        )
    }

    static func message(
        message: String?,
        messageType: Property.MessageType,
        severity: Property.Severity,
        diagnosticsId: String? = nil,
        context: [String: Any]? = nil
    ) -> Self {
        .init(
            eventType: .message,
            properties: MessageEventProperties(
                message: message,
                messageType: messageType,
                severity: severity,
                diagnosticsId: diagnosticsId,
                context: context
            )
        )
    }

    static func ui(
        action: Property.Action,
        context: Property.Context?,
        extra: String?,
        objectType: Property.ObjectType,
        objectId: Property.ObjectId?,
        objectClass: String?,
        place: Property.Place
    ) -> Self {
        .init(
            eventType: .ui,
            properties: UIEventProperties(
                action: action,
                context: context,
                extra: extra,
                objectType: objectType,
                objectId: objectId,
                objectClass: objectClass,
                place: place
            )
        )
    }

    static func networkCall(
        callType: Property.NetworkCallType,
        id: String,
        url: String,
        method: HTTPMethod,
        errorBody: String?,
        responseCode: Int?,
        duration: TimeInterval? = nil
    ) -> Self {
        .init(
            eventType: .networkCall,
            properties: NetworkCallEventProperties(
                callType: callType,
                id: id,
                url: url,
                method: method,
                errorBody: errorBody,
                responseCode: responseCode,
                duration: duration
            )
        )
    }

    static func networkConnectivity(networkType: Connectivity.NetworkType = Connectivity.networkType) -> Self {
        .init(
            eventType: .networkConnectivity,
            properties: NetworkConnectivityEventProperties(networkType: networkType)
        )
    }

    static func appLifecycle(_ lifecycleType: AppLifecycleEventProperties.LifecycleType) -> Self {
        Analytics.Event(
            eventType: .appLifecycle,
            properties: AppLifecycleEventProperties(lifecycleType: lifecycleType)
        )
    }

    static func timer(
        momentType: Property.TimerType,
        id: String?,
        duration: TimeInterval? = nil,
        context: [String: Any]? = nil
    ) -> Self {
        .init(
            eventType: .timerEvent,
            properties: TimerEventProperties(
                momentType: momentType,
                id: id,
                duration: duration,
                context: context
            )
        )
    }

    enum DropInLoadingSource: String {
        case universalCheckout = "UNIVERSAL_CHECKOUT"
        case showPaymentMethod = "SHOW_PAYMENT_METHOD"
        case vaultManager = "VAULT_MANAGER"
    }

    static func dropInLoading(
        duration: Int,
        source: DropInLoadingSource
    ) -> Self {
        .timer(
            momentType: .end,
            id: "DROP_IN_LOADING",
            duration: TimeInterval(duration),
            context: ["source": source.rawValue]
        )
    }

    static func headlessLoading(duration: Int) -> Self {
        .timer(momentType: .end, id: "HEADLESS_LOADING", duration: TimeInterval(duration))
    }

    enum ConfigurationLoadingSource: String {
        case cache = "CACHE"
        case network = "NETWORK"
    }

    static func configurationLoading(
        duration: Int,
        source: ConfigurationLoadingSource
    ) -> Self {
        .timer(
            momentType: .end,
            id: "CONFIGURATION_LOADING",
            duration: TimeInterval(duration),
            context: ["source": source.rawValue]
        )
    }

    static func allImagesLoading(
        momentType: Property.TimerType,
        id: String?
    ) -> Self {
        .init(
            eventType: .paymentMethodAllImagesLoading,
            properties: TimerEventProperties(
                momentType: momentType,
                id: id
            )
        )
    }

    static func imageLoading(
        momentType: Property.TimerType,
        id: String?
    ) -> Self {
        .init(
            eventType: .paymentMethodImageLoading,
            properties: TimerEventProperties(
                momentType: momentType,
                id: id
            )
        )
    }
}
// swiftlint:enable all
