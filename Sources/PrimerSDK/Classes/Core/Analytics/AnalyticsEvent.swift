//
//  Analytics.swift
//  PrimerSDK
//
//  Created by Evangelos on 13/12/21.
//

#if canImport(UIKit)

import Foundation

extension Analytics.Event {
    
    enum EventType: String, Codable {
        case ui = "UI_EVENT"
        case crash = "APP_CRASHED_EVENT"
        case message = "MESSAGE_EVENT"
        case networkCall = "NETWORK_CALL_EVENT"
        case networkConnectivity = "NETWORK_CONNECTIVITY_EVENT"
        case sdkEvent = "SDK_FUNCTION_EVENT"
        case timerEvent = "TIMER_EVENT"
        case paymentMethodImageLoading = "PM_IMAGE_LOADING_DURATION"
        case paymentMethodAllImagesLoading = "PM_ALL_IMAGES_LOADING_DURATION"
    }
    
    struct Property {
        enum Action: String, Codable {
            case blur = "BLUR"
            case click = "CLICK"
            case focus = "FOCUS"
            case view = "VIEW"
        }
        
        struct Context: Codable {
            var issuerId: String?
            var paymentMethodType: String?
            var url: String?
        }
        
        enum MessageType: String, Codable {
            case error = "ERROR"
            case missingValue = "MISSING_VALUE"
            case paymentMethodImageLoadingFailed = "PM_IMAGE_LOADING_FAILED"
            case validationFailed = "VALIDATION_FAILED"
        }
        
        enum TimerType: String, Codable {
            case start = "START"
            case end = "END"
        }
        
        enum NetworkCallType: String, Codable {
            case requestStart = "REQUEST_START"
            case requestEnd = "REQUEST_END"
        }
        
        enum ObjectType: String, Codable {
            case alert = "ALERT"
            case button = "BUTTON"
            case image = "IMAGE"
            case input = "INPUT"
            case label = "LABEL"
            case listItem = "LIST_ITEM"
            case loader = "LOADER"
            case view = "VIEW"
            case webpage = "WEB_PAGE"
        }
        
        enum ObjectId: String, Codable {
            case back = "BACK"
            case cancel = "CANCEL"
            case cardHolder = "CARD_HOLDER"
            case cardNumber = "CARD_NUMBER"
            case cvc = "CVC"
            case delete = "DELETE"
            case done = "DONE"
            case edit = "EDIT"
            case expiry = "EXPIRY"
            case ibank = "IBAN"
            case otp = "OTP"
            case seeAll = "SEE_ALL"
            case select = "SELECT"
            case pay = "PAY"
            case phone = "PHONE"
            case retry = "RETRY"
            case submit = "SUBMIT"
            case billingAddressPostalCode = "BILLING_ADDRESS_POSTAL_CODE"
            case billingAddressFirstName = "BILLING_ADDRESS_FIRST_NAME"
            case billingAddressLastName = "BILLING_ADDRESS_LAST_NAME"
            case billingAddressLine1 = "BILLING_ADDRESS_LINE_1"
            case billingAddressLine2 = "BILLING_ADDRESS_LINE_2"
            case billingAddressCity = "BILLING_ADDRESS_CITY"
            case billingAddressState = "BILLING_ADDRESS_STATE"
            case billingAddressCountry = "BILLING_ADDRESS_COUNTRY"
        }
        
        enum Place: String, Codable {
            case bankSelectionList = "BANK_SELECTION_LIST"
            case countrySelectionList = "COUNTRY_SELECTION_LIST"
            case retailSelectionList = "RETAIL_SELECTION_LIST"
            case cardForm = "CARD_FORM"
            case directCheckout = "DIRECT_CHECKOUT"
            case dynamicForm = "DYNAMIC_FORM"
            case errorScreen = "ERROR_SCREEN"
            case paymentMethodsList = "PAYMENT_METHODS_LIST"
            case paymentMethodLoading = "PAYMENT_METHOD_LOADING"
            case paymentMethodPopup = "PAYMENT_METHOD_POPUP"
            case sdkLoading = "SDK_LOADING"
            case successScreen = "SUCCESS_SCREEN"
            case vaultManager = "VAULT_MANAGER"
            case webview = "WEBVIEW"
            case universalCheckout = "UNIVERSAL_CHECKOUT"
        }
        
        enum Severity: String, Codable {
            case debug = "DEBUG"
            case info = "INFO"
            case warning = "WARNING"
            case error = "ERROR"
        }
    }
    
}

protocol AnalyticsEventProperties: Codable {}

struct CrashEventProperties: AnalyticsEventProperties {
    
    var stacktrace: [String]
    var params: [String: AnyCodable]?
    
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
}

struct MessageEventProperties: AnalyticsEventProperties {
    
    var message: String?
    var messageType: Analytics.Event.Property.MessageType
    var severity: Analytics.Event.Property.Severity
    var diagnosticsId: String?
}

struct NetworkCallEventProperties: AnalyticsEventProperties {
    
    var callType: Analytics.Event.Property.NetworkCallType
    var id: String
    var url: String
    var method: HTTPMethod
    var errorBody: String?
    var responseCode: Int?
    var params: [String: AnyCodable]?
    
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
}

struct NetworkConnectivityEventProperties: AnalyticsEventProperties {
    
    var networkType: Connectivity.NetworkType
    var params: [String: AnyCodable]?
    
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
}

struct SDKEventProperties: AnalyticsEventProperties {
    
    var name: String
    var params: [String: AnyCodable]?
    
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
}

struct TimerEventProperties: AnalyticsEventProperties {
    
    var momentType: Analytics.Event.Property.TimerType
    var id: String?
    var params: [String: AnyCodable]?
    
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
        case clientToken, integrationType, paymentMethodType,
             sdkIntegrationType, sdkIntent, sdkPaymentHandling,
             sdkSessionId, sdkSettings, sdkType, sdkVersion
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
        self.sdkVersion = Bundle.primerFramework.releaseVersionNumber
        
        if let settingsDict = try? PrimerSettings.current.asDictionary(),
            let settingsData = try? JSONSerialization.data(withJSONObject: settingsDict, options: .fragmentsAllowed) {
            let decoder = JSONDecoder()
            if let anyDecodableDictionary = try? decoder.decode([String: AnyCodable].self, from: settingsData) {
                self.sdkSettings = anyDecodableDictionary
                return
            }
        }
        
        self.sdkSettings = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if let clientToken {
            try container.encode(clientToken, forKey: .clientToken)
        }
        
        if let integrationType {
            try container.encode(integrationType, forKey: .integrationType)
        }
        
        if let paymentMethodType {
            try container.encode(paymentMethodType, forKey: .paymentMethodType)
        }
        
        if let sdkIntent {
            try container.encode(sdkIntent, forKey: .sdkIntent)
        }
        
        if let sdkPaymentHandling {
            try container.encode(sdkPaymentHandling, forKey: .sdkPaymentHandling)
        }
        
        if let sdkSettings {
            try container.encode(sdkSettings, forKey: .sdkSettings)
        }
    }
}

#endif
