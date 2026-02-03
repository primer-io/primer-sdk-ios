//
//  EventType.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

public extension Analytics.Event {

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
        public enum Action: String, Codable {
            case blur       = "BLUR"
            case click      = "CLICK"
            case focus      = "FOCUS"
            case view       = "VIEW"
            case present    = "PRESENT"
            case dismiss    = "DISMISS"
        }

        public struct Context: Codable {

            var issuerId: String?
            var paymentMethodType: String?
            var cardNetworks: [String]?
            var url: String?
            var iPay88PaymentMethodId: String?
            var iPay88ActionType: String?

            public init(
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

        public enum MessageType: String, Codable {
            case error                              = "ERROR"
            case missingValue                       = "MISSING_VALUE"
            case paymentMethodImageLoadingFailed    = "PM_IMAGE_LOADING_FAILED"
            case validationFailed                   = "VALIDATION_FAILED"
            case info                               = "INFO"
            case other                              = "OTHER"
            case retry                              = "RETRY"
            case retryFailed                        = "RETRY_FAILED"
            case retrySuccess                       = "RETRY_SUCCESS"
        }

        public enum TimerType: String, Codable {
            case start  = "START"
            case end    = "END"
        }

        public enum NetworkCallType: String, Codable {
            case requestStart   = "REQUEST_START"
            case requestEnd     = "REQUEST_END"
        }

        public enum ObjectType: String, Codable {
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

        public enum ObjectId: String, Codable {
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

        public enum Place: String, Codable {
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

        public enum Severity: String, Codable {
            case debug      = "DEBUG"
            case info       = "INFO"
            case warning    = "WARNING"
            case error      = "ERROR"
        }
    }
}
