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
}

struct MessageEventProperties: AnalyticsEventProperties {
    var message: String?
    var messageType: Analytics.Event.Property.MessageType
    var severity: Analytics.Event.Property.Severity
}

struct NetworkCallEventProperties: AnalyticsEventProperties {
    var callType: Analytics.Event.Property.NetworkCallType
    var id: String
    var url: String
    var method: HTTPMethod
    var errorBody: String?
    var responseCode: Int?
}

struct NetworkConnectivityEventProperties: AnalyticsEventProperties {
    var networkType: Connectivity.NetworkType
}

struct SDKEventProperties: AnalyticsEventProperties {
    var name: String
    var params: [String: String]?
}

struct TimerEventProperties: AnalyticsEventProperties {
    var momentType: Analytics.Event.Property.TimerType
    var id: String?
}

struct UIEventProperties: AnalyticsEventProperties {
    var action: Analytics.Event.Property.Action
    var context: Analytics.Event.Property.Context?
    var extra: String?
    var objectType: Analytics.Event.Property.ObjectType
    var objectId: Analytics.Event.Property.ObjectId?
    var objectClass: String?
    var place: Analytics.Event.Property.Place
}

#endif
