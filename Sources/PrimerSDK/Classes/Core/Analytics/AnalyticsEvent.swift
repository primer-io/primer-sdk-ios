//
//  Analytics.swift
//  PrimerSDK
//
//  Created by Evangelos on 13/12/21.
//

import Foundation

// swiftlint:disable all
extension Analytics {
    struct Event: Codable, Equatable {

        static func == (lhs: Analytics.Event, rhs: Analytics.Event) -> Bool {
            return lhs.localId == rhs.localId
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

        fileprivate init(eventType: Analytics.Event.EventType,
                         properties: AnalyticsEventProperties?,
                         analyticsUrl: String? = PrimerAPIConfigurationModule.decodedJWTToken?.analyticsUrlV2) {
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
            } else if let timerEventProperties = properties as? TimerEventProperties {
                try? container.encode(timerEventProperties, forKey: .properties)
            } else if let uiEventProperties = properties as? UIEventProperties {
                try? container.encode(uiEventProperties, forKey: .properties)
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
            } else if let timerEventProperties = (try? container.decode(TimerEventProperties?.self, forKey: .properties)) {
                self.properties = timerEventProperties
            } else if let uiEventProperties = (try? container.decode(UIEventProperties?.self, forKey: .properties)) {
                self.properties = uiEventProperties
            } else {
                self.properties = nil
            }
        }
    }
}

extension Analytics.Event {

    enum EventType: String, Codable {
        case ui                             = "UI_EVENT"
        case crash                          = "APP_CRASHED_EVENT"
        case message                        = "MESSAGE_EVENT"
        case networkCall                    = "NETWORK_CALL_EVENT"
        case networkConnectivity            = "NETWORK_CONNECTIVITY_EVENT"
        case sdkEvent                       = "SDK_FUNCTION_EVENT"
        case timerEvent                     = "TIMER_EVENT"
        case paymentMethodImageLoading      = "PM_IMAGE_LOADING_DURATION"
        case paymentMethodAllImagesLoading  = "PM_ALL_IMAGES_LOADING_DURATION"
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

protocol AnalyticsEventProperties: Codable {}

struct MessageEventProperties: AnalyticsEventProperties {

    var message: String?
    var messageType: Analytics.Event.Property.MessageType
    var severity: Analytics.Event.Property.Severity
    var diagnosticsId: String?
    var context: [String: Any]?

    private enum CodingKeys: String, CodingKey {
        case message
        case messageType
        case severity
        case diagnosticsId
        case context
    }

    fileprivate init(
        message: String?,
        messageType: Analytics.Event.Property.MessageType,
        severity: Analytics.Event.Property.Severity,
        diagnosticsId: String? = nil,
        context: [String: Any]? = nil
    ) {
        self.message = message
        self.messageType = messageType
        self.severity = severity
        self.diagnosticsId = diagnosticsId
        self.context = context
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.message = try container.decodeIfPresent(String.self, forKey: .message)
        self.messageType = try container.decode(Analytics.Event.Property.MessageType.self, forKey: .messageType)
        self.severity = try container.decode(Analytics.Event.Property.Severity.self, forKey: .severity)
        self.diagnosticsId = try container.decodeIfPresent(String.self, forKey: .diagnosticsId)
        self.context = try container.decodeIfPresent([String: Any].self, forKey: .context)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(message, forKey: .message)
        try container.encode(messageType, forKey: .messageType)
        try container.encode(severity, forKey: .severity)
        try container.encodeIfPresent(diagnosticsId, forKey: .diagnosticsId)
        try container.encodeIfPresent(context, forKey: .context)
    }
}

struct NetworkCallEventProperties: AnalyticsEventProperties {

    var callType: Analytics.Event.Property.NetworkCallType
    var id: String
    var url: String
    var method: HTTPMethod
    var errorBody: String?
    var responseCode: Int?
    var params: [String: AnyCodable]?

    private enum CodingKeys: String, CodingKey {
        case callType
        case id
        case url
        case method
        case errorBody
        case responseCode
        case params
    }

    fileprivate init(
        callType: Analytics.Event.Property.NetworkCallType,
        id: String,
        url: String,
        method: HTTPMethod,
        errorBody: String?,
        responseCode: Int?
    ) {
        self.callType = callType
        self.id = id
        self.url = url
        self.method = method
        self.errorBody = errorBody
        self.responseCode = responseCode

        let sdkProperties = SDKProperties()
        if let sdkPropertiesDict = try? sdkProperties.asDictionary(),
           let data = try? JSONSerialization.data(withJSONObject: sdkPropertiesDict, options: .fragmentsAllowed) {
            let decoder = JSONDecoder()
            if let anyDecodableDictionary = try? decoder.decode([String: AnyCodable].self, from: data) {
                self.params = anyDecodableDictionary
            }
        } else {
            self.params = nil
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.callType = try container.decode(Analytics.Event.Property.NetworkCallType.self, forKey: .callType)
        self.id = try container.decode(String.self, forKey: .id)
        self.url = try container.decode(String.self, forKey: .url)
        self.method = try container.decode(HTTPMethod.self, forKey: .method)
        self.errorBody = try container.decodeIfPresent(String.self, forKey: .errorBody)
        self.responseCode = try container.decodeIfPresent(Int.self, forKey: .responseCode)
        self.params = try container.decodeIfPresent([String: AnyCodable].self, forKey: .params)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(callType, forKey: .callType)
        try container.encode(id, forKey: .id)
        try container.encode(url, forKey: .url)
        try container.encode(method, forKey: .method)
        try container.encodeIfPresent(errorBody, forKey: .errorBody)
        try container.encodeIfPresent(responseCode, forKey: .responseCode)
        try container.encodeIfPresent(params, forKey: .params)
    }
}

struct NetworkConnectivityEventProperties: AnalyticsEventProperties {

    var networkType: Connectivity.NetworkType
    var params: [String: AnyCodable]?

    private enum CodingKeys: String, CodingKey {
        case networkType
        case params
    }

    fileprivate init(networkType: Connectivity.NetworkType) {
        self.networkType = networkType

        let sdkProperties = SDKProperties()
        if let sdkPropertiesDict = try? sdkProperties.asDictionary(),
           let data = try? JSONSerialization.data(withJSONObject: sdkPropertiesDict, options: .fragmentsAllowed) {
            let decoder = JSONDecoder()
            if let anyDecodableDictionary = try? decoder.decode([String: AnyCodable].self, from: data) {
                self.params = anyDecodableDictionary
            }
        } else {
            self.params = nil
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.networkType = try container.decode(Connectivity.NetworkType.self, forKey: .networkType)
        self.params = try container.decodeIfPresent([String: AnyCodable].self, forKey: .params)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(networkType, forKey: .networkType)
        try container.encodeIfPresent(params, forKey: .params)
    }
}

struct SDKEventProperties: AnalyticsEventProperties {

    var name: String
    var params: [String: AnyCodable]?

    private enum CodingKeys: String, CodingKey {
        case name
        case params
    }

    fileprivate init(name: String, params: [String: String]?) {
        self.name = name

        var parameters: [String: Any] = params ?? [:]

        let sdkProperties = SDKProperties()
        if let sdkPropertiesDict = try? sdkProperties.asDictionary() {
            parameters.merge(sdkPropertiesDict) {(current, _) in current}
        }

        if !parameters.isEmpty,
           let parametersData = try? JSONSerialization.data(withJSONObject: parameters, options: .fragmentsAllowed) {
            let decoder = JSONDecoder()
            if let anyDecodableDictionary = try? decoder.decode([String: AnyCodable].self, from: parametersData) {
                self.params = anyDecodableDictionary
            }
        } else {
            self.params = nil
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.params = try container.decodeIfPresent([String: AnyCodable].self, forKey: .params)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(params, forKey: .params)
    }
}

struct TimerEventProperties: AnalyticsEventProperties {

    var momentType: Analytics.Event.Property.TimerType
    var id: String?
    var params: [String: AnyCodable]?

    private enum CodingKeys: String, CodingKey {
        case momentType
        case id
        case params
    }

    fileprivate init(
        momentType: Analytics.Event.Property.TimerType,
        id: String?
    ) {
        self.momentType = momentType
        self.id = id

        let sdkProperties = SDKProperties()
        if let sdkPropertiesDict = try? sdkProperties.asDictionary(),
           let data = try? JSONSerialization.data(withJSONObject: sdkPropertiesDict, options: .fragmentsAllowed) {
            let decoder = JSONDecoder()
            if let anyDecodableDictionary = try? decoder.decode([String: AnyCodable].self, from: data) {
                self.params = anyDecodableDictionary
            }
        } else {
            self.params = nil
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.momentType = try container.decode(Analytics.Event.Property.TimerType.self, forKey: .momentType)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.params = try container.decodeIfPresent([String: AnyCodable].self, forKey: .params)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(momentType, forKey: .momentType)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(params, forKey: .params)
    }
}

struct UIEventProperties: AnalyticsEventProperties {

    var action: Analytics.Event.Property.Action
    var context: Analytics.Event.Property.Context?
    var extra: String?
    var objectType: Analytics.Event.Property.ObjectType
    var objectId: Analytics.Event.Property.ObjectId?
    var objectClass: String?
    var place: Analytics.Event.Property.Place
    var params: [String: String]?

    private enum CodingKeys: String, CodingKey {
        case action
        case context
        case extra
        case objectType
        case objectId
        case objectClass
        case place
        case params
    }

    fileprivate init(
        action: Analytics.Event.Property.Action,
        context: Analytics.Event.Property.Context?,
        extra: String?,
        objectType: Analytics.Event.Property.ObjectType,
        objectId: Analytics.Event.Property.ObjectId?,
        objectClass: String?,
        place: Analytics.Event.Property.Place
    ) {
        self.action = action
        self.context = context
        self.extra = extra
        self.objectType = objectType
        self.objectId = objectId
        self.objectClass = objectClass
        self.place = place

        if let jsonData = try? JSONEncoder().encode(SDKProperties()),
           let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments),
           let params = jsonObject as? [String: String] {
            self.params = params
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.action = try container.decode(Analytics.Event.Property.Action.self, forKey: .action)
        self.context = try container.decodeIfPresent(Analytics.Event.Property.Context.self, forKey: .context)
        self.extra = try container.decodeIfPresent(String.self, forKey: .extra)
        self.objectType = try container.decode(Analytics.Event.Property.ObjectType.self, forKey: .objectType)
        self.objectId = try container.decodeIfPresent(Analytics.Event.Property.ObjectId.self, forKey: .objectId)
        self.objectClass = try container.decodeIfPresent(String.self, forKey: .objectClass)
        self.place = try container.decode(Analytics.Event.Property.Place.self, forKey: .place)
        self.params = try container.decodeIfPresent([String: String].self, forKey: .params)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(action, forKey: .action)
        try container.encodeIfPresent(context, forKey: .context)
        try container.encodeIfPresent(extra, forKey: .extra)
        try container.encode(objectType, forKey: .objectType)
        try container.encodeIfPresent(objectId, forKey: .objectId)
        try container.encodeIfPresent(objectClass, forKey: .objectClass)
        try container.encode(place, forKey: .place)
        try container.encode(params, forKey: .params)
    }
}

struct SDKProperties: Codable {

    let clientToken: String?
    let integrationType: String?
    let paymentMethodType: String?
    let sdkIntegrationType: PrimerSDKIntegrationType?
    let sdkIntent: PrimerSessionIntent?
    let sdkPaymentHandling: PrimerPaymentHandling?
    let sdkSessionId: String?
    let sdkSettings: [String: AnyCodable]?
    let sdkType: String?
    let sdkVersion: String?

    private enum CodingKeys: String, CodingKey {
        case clientToken
        case integrationType
        case paymentMethodType
        case sdkIntegrationType
        case sdkIntent
        case sdkPaymentHandling
        case sdkSessionId
        case sdkSettings
        case sdkType
        case sdkVersion
    }

    fileprivate init() {
        self.clientToken = AppState.current.clientToken
        self.sdkIntegrationType = PrimerInternal.shared.sdkIntegrationType
        #if COCOAPODS
        self.integrationType = "COCOAPODS"
        #else
        self.integrationType = "SPM"
        #endif
        self.paymentMethodType = PrimerInternal.shared.selectedPaymentMethodType
        self.sdkIntent = PrimerInternal.shared.intent
        self.sdkPaymentHandling = PrimerSettings.current.paymentHandling
        self.sdkSessionId = PrimerInternal.shared.checkoutSessionId

        self.sdkType = Primer.shared.integrationOptions?.reactNativeVersion == nil ? "IOS_NATIVE" : "RN_IOS"
        self.sdkVersion = VersionUtils.releaseVersionNumber

        if let settingsData = try? JSONEncoder().encode(PrimerSettings.current) {
            let decoder = JSONDecoder()
            if let anyDecodableDictionary = try? decoder.decode([String: AnyCodable].self, from: settingsData) {
                self.sdkSettings = anyDecodableDictionary
                return
            }
        }

        self.sdkSettings = nil
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.clientToken = try container.decodeIfPresent(String.self, forKey: .clientToken)
        self.integrationType = try container.decodeIfPresent(String.self, forKey: .integrationType)
        self.paymentMethodType = try container.decodeIfPresent(String.self, forKey: .paymentMethodType)
        self.sdkIntegrationType = try container.decodeIfPresent(PrimerSDKIntegrationType.self, forKey: .sdkIntegrationType)
        self.sdkIntent = try container.decodeIfPresent(PrimerSessionIntent.self, forKey: .sdkIntent)
        self.sdkPaymentHandling = try container.decodeIfPresent(PrimerPaymentHandling.self, forKey: .sdkPaymentHandling)
        self.sdkSessionId = try container.decodeIfPresent(String.self, forKey: .sdkSessionId)
        self.sdkSettings = try container.decodeIfPresent([String: AnyCodable].self, forKey: .sdkSettings)
        self.sdkType = try container.decodeIfPresent(String.self, forKey: .sdkType)
        self.sdkVersion = try container.decodeIfPresent(String.self, forKey: .sdkVersion)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(clientToken, forKey: .clientToken)
        try container.encodeIfPresent(integrationType, forKey: .integrationType)
        try container.encodeIfPresent(paymentMethodType, forKey: .paymentMethodType)
        try container.encodeIfPresent(sdkIntent, forKey: .sdkIntent)
        try container.encodeIfPresent(sdkPaymentHandling, forKey: .sdkPaymentHandling)
        try container.encodeIfPresent(sdkSettings, forKey: .sdkSettings)
        try container.encodeIfPresent(sdkSessionId, forKey: .sdkSessionId)
        try container.encodeIfPresent(sdkSettings, forKey: .sdkSettings)
        try container.encodeIfPresent(sdkType, forKey: .sdkType)
        try container.encodeIfPresent(sdkVersion, forKey: .sdkVersion)
    }
}

extension Analytics.Event {

    static func sdk(name: String, params: [String: String]?) -> Self {
        return .init(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: name,
                params: params
            )
        )
    }

    static func message(message: String?,
                        messageType: Property.MessageType,
                        severity: Property.Severity,
                        diagnosticsId: String? = nil,
                        context: [String: Any]? = nil) -> Self {
        return .init(
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

    static func ui(action: Property.Action,
                   context: Property.Context?,
                   extra: String?,
                   objectType: Property.ObjectType,
                   objectId: Property.ObjectId?,
                   objectClass: String?,
                   place: Property.Place) -> Self {
        return .init(
            eventType: .ui,
            properties: UIEventProperties(
                action: action,
                context: context,
                extra: extra,
                objectType: objectType,
                objectId: objectId,
                objectClass: objectClass,
                place: place)
        )
    }

    static func networkCall(callType: Property.NetworkCallType,
                            id: String,
                            url: String,
                            method: HTTPMethod,
                            errorBody: String?,
                            responseCode: Int?) -> Self {
        return .init(
            eventType: .networkCall,
            properties: NetworkCallEventProperties(
                callType: callType,
                id: id,
                url: url,
                method: method,
                errorBody: errorBody,
                responseCode: responseCode
            )
        )
    }

    static func networkConnectivity(networkType: Connectivity.NetworkType = Connectivity.networkType) -> Self {
        return .init(
            eventType: .networkConnectivity,
            properties: NetworkConnectivityEventProperties(networkType: networkType)
        )
    }

    static func timer(momentType: Property.TimerType,
                      id: String?) -> Self {
        return .init(
            eventType: .timerEvent,
            properties: TimerEventProperties(
                momentType: momentType,
                id: id
            )
        )
    }

    static func allImagesLoading(momentType: Property.TimerType,
                                 id: String?) -> Self {
        return .init(
            eventType: .paymentMethodAllImagesLoading,
            properties: TimerEventProperties(
                momentType: momentType,
                id: id
            )
        )
    }

    static func imageLoading(momentType: Property.TimerType,
                             id: String?) -> Self {
        return .init(
            eventType: .paymentMethodImageLoading,
            properties: TimerEventProperties(
                momentType: momentType,
                id: id
            )
        )
    }
}
// swiftlint:enable all
