//
//  Analytics.swift
//  PrimerSDK
//
//  Created by Evangelos on 13/12/21.
//



import Foundation

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
            var url: String?
            var iPay88PaymentMethodId: String?
            var iPay88ActionType: String?
            
            init(
                issuerId: String? = nil,
                paymentMethodType: String? = nil,
                url: String? = nil,
                iPay88PaymentMethodId: String? = nil,
                iPay88ActionType: String? = nil
            ) {
                self.issuerId = issuerId
                self.paymentMethodType = paymentMethodType
                self.url = url
                self.iPay88PaymentMethodId = iPay88PaymentMethodId
                self.iPay88ActionType = iPay88ActionType
            }
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: Analytics.Event.Property.Context.CodingKeys.self)
                try container.encodeIfPresent(self.issuerId, forKey: Analytics.Event.Property.Context.CodingKeys.issuerId)
                try container.encodeIfPresent(self.paymentMethodType, forKey: Analytics.Event.Property.Context.CodingKeys.paymentMethodType)
                try container.encodeIfPresent(self.url, forKey: Analytics.Event.Property.Context.CodingKeys.url)
                try container.encodeIfPresent(self.iPay88PaymentMethodId, forKey: Analytics.Event.Property.Context.CodingKeys.iPay88PaymentMethodId)
                try container.encodeIfPresent(self.iPay88ActionType, forKey: Analytics.Event.Property.Context.CodingKeys.iPay88ActionType)
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

struct CrashEventProperties: AnalyticsEventProperties {
    
    var stacktrace: [String]
    var params: [String: AnyCodable]?
    
    private enum CodingKeys: String, CodingKey {
        case stacktrace
        case params
    }
    
    init(stacktrace: [String]) {
        self.stacktrace = stacktrace
        
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
        stacktrace = try container.decode([String].self, forKey: .stacktrace)
        params = try container.decodeIfPresent([String: AnyCodable].self, forKey: .params)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.stacktrace, forKey: .stacktrace)
        try container.encodeIfPresent(self.params, forKey: .params)
    }
}

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
    
    init(
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
    
    init(
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
    
    init(networkType: Connectivity.NetworkType) {
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
    
    init(name: String, params: [String: String]?) {
        self.name = name
        
        var _params: [String: Any] = params ?? [:]
        
        let sdkProperties = SDKProperties()
        if let sdkPropertiesDict = try? sdkProperties.asDictionary() {
            _params.merge(sdkPropertiesDict) {(current,_) in current}
        }
        
        if !_params.isEmpty, let _paramsData = try? JSONSerialization.data(withJSONObject: _params, options: .fragmentsAllowed) {
            let decoder = JSONDecoder()
            if let anyDecodableDictionary = try? decoder.decode([String: AnyCodable].self, from: _paramsData) {
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
    
    init(
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
    
    init(
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
           let params = jsonObject as? [String: String]
        {
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
    
    init() {
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


