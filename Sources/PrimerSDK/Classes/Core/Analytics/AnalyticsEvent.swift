//
//  Analytics.swift
//  PrimerSDK
//
//  Created by Evangelos on 13/12/21.
//

#if canImport(UIKit)

import Foundation

extension Analytics.Event {
    
    enum `Type`: String, Codable {
        case ui = "UI_EVENT"
        case crash = "APP_CRASHED_EVENT"
        case message = "MESSAGE_EVENT"
        case network = "NETWORK_CALL_EVENT"
        case networkConnectivity = "NETWORK_CONNECTIVITY_EVENT"
    }
    
    struct Properties {
        var action: Analytics.Event.Property.Action?
        var callType: Analytics.Event.Property.NetworkCall?
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
            case click = "CLICK"
            case view = "VIEW"
        }
        
        enum Message: String, Codable {
            case missingAmount = "MISSING_AMOUNT"
            case missingCountryCode = "MISSING_COUNTRY_CODE"
            case missingOrder = "MISSING_ORDER"
            case missingAuthToken = "MISSING_AUTH_TOKEN"
            case validationFailed = "VALIDATION_FAILED"
        }
        
        enum NetworkCall: String, Codable {
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
            case paymentMethodsList = "PAYMENT_METHODS_LIST"
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

#endif
