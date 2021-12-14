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
    }
    
    struct Properties {
        var action: Analytics.Event.Property.Action?
        var callType: Analytics.Event.Property.NetworkCallType?
        var errorBody: String?
        var extra: String?
        var extraProperties: [String: String]?
        var id: String?
        var message: String?
        var messageType: Analytics.Event.Property.Message?
        var method: HTTPMethod?
        var objectType: Analytics.Event.Property.ObjectType?
        var place: Analytics.Event.Property.Place?
        var responseCode: Int?
        var severity: Analytics.Event.Property.Severity?
        var stacktrace: [String]?
        var url: String?
        
        var jsonValue: [String: String]? {
            var json: [String: String] = [:]
            
            if let val = action {
                json["action"] = val.rawValue
            }
            
            if let val = callType {
                json["callType"] = val.rawValue
            }
            
            if let val = errorBody {
                json["errorBody"] = val
            }
            
            if let val = extra {
                json["extra"] = val
            }
            
            if let val = id {
                json["id"] = val
            }
            
            if let val = message {
                json["message"] = val
            }
            
            if let val = messageType {
                json["messageType"] = val.rawValue
            }
            
            if let val = method {
                json["method"] = val.rawValue
            }
            
            if let val = objectType {
                json["objectType"] = val.rawValue
            }
            
            if let val = place {
                json["place"] = val.rawValue
            }
            
            if let val = responseCode {
                json["responseCode"] = String(val)
            }
            
            if let val = severity {
                json["severity"] = val.rawValue
            }
            
            if let val = stacktrace {
//                json["stacktrace"] = val
            }
            
            if let val = url {
                json["url"] = val
            }
            
            
            return json.merging(extraProperties ?? [:]) { (_, new) in new }
        }
        
    }
    
    struct Property {
        enum Action: String, Codable {
            case blur = "BLUR"
            case click = "CLICK"
            case focus = "FOCUS"
            case view = "VIEW"
        }
        
        enum Context: String, Codable {
            case apaya = "APAYA"
            case apple = "APPLE"
            case klarna = "KLARNA"
            case paymentCard = "PAYMENT_CARD"
            case paypal = "PAYPAL"
        }
        
        enum Message: String, Codable {
            case missingAmount = "MISSING_AMOUNT"
            case missingCountryCode = "MISSING_COUNTRY_CODE"
            case missingOrder = "MISSING_ORDER"
            case missingAuthToken = "MISSING_AUTH_TOKEN"
            case validationFailed = "VALIDATION_FAILED"
        }
        
        enum MomentType: String, Codable {
            case start = "START"
            case end = "END"
        }
        
        enum NetworkCallType: String, Codable {
            case requestStart = "REQUEST_START"
            case requestEnd = "REQUEST_END"
        }
        
        enum ObjectType: String, Codable {
            case button = "BUTTON"
            case textField = "TEXT_FIELD"
            case view = "VIEW"
        }
        
        enum Place: String, Codable {
            case bankSelectionList = "BANK_SELECTION_LIST"
            case cardForm = "CARD_FORM"
            case failureScreen = "FAILURE_SCREEN"
            case loading = "LOADING"
            case paymentMethodsList = "PAYMENT_METHODS_LIST"
            case successScreen = "SUCCESS_SCREEN"
            case universalCheckout = "UNIVERSAL_CHECKOUT"
            case vaultManager = "VAULT_MANAGER"
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
    var networkType: String
}

struct NetworkCallEventProperties: AnalyticsEventProperties {
    var callType: Analytics.Event.Property.NetworkCallType
    var id: String
    var url: String
    var method: HTTPMethod
    var errorBody: String?
    var responseCode: Int?
}

struct SDKEventProperties: AnalyticsEventProperties {
    var name: String
    var params: [String: String]?
}

struct TimerEventProperties: AnalyticsEventProperties {
    var momentType: Analytics.Event.Property.MomentType
    var id: String?
}

struct UIEventProperties: AnalyticsEventProperties {
    var action: Analytics.Event.Property.Action
    var context: String? //Analytics.Event.Property.Context?
    var extra: String?
    var objectType: Analytics.Event.Property.ObjectType
    var objectId: String?
    var place: Analytics.Event.Property.Place
}

#endif
