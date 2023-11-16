//
//  KlarnaAnalyticsEvents.swift
//  PrimerSDK
//
//  Created by Illia Khrypunov on 06.11.2023.
//

import Foundation

struct KlarnaAnalyticsEvents {
    // session creation component
    static let CREATE_SESSION_UPDATE_COLLECTED_DATA_METHOD = "KlarnaPaymentSessionCreationComponent.updateCollectedData()"
    static let CREATE_SESSION_START_METHOD = "KlarnaPaymentSessionCreationComponent.start()"
    
    // view handling component
    static let CREATE_PAYMENT_VIEW_METHOD = "KlarnaPaymentViewHandlingComponent.createPaymentView()"
    static let REMOVE_PAYMENT_VIEW_METHOD = "KlarnaPaymentViewHandlingComponent.removePaymentView()"
    static let INIT_PAYMENT_VIEW_METHOD = "KlarnaPaymentViewHandlingComponent.initPaymentView()"
    static let LOAD_PAYMENT_VIEW_METHOD = "KlarnaPaymentViewHandlingComponent.loadPaymentView(jsonData: String?)"
    static let LOAD_PAYMENT_REVIEW_METHOD = "KlarnaPaymentViewHandlingComponent.loadPaymentReview(jsonData: String?)"
    
    // session authorization component
    static let AUTHORIZE_SESSION_METHOD = "KlarnaPaymentSessionAuthorizationComponent.authorizeSession(autoFinalize: Bool, jsonData: String?)"
    static let REAUTHORIZE_SESSION_METHOD = "KlarnaPaymentSessionAuthorizationComponent.reauthorizeSession(jsonData: String?)"
    
    // session finalization component
    static let FINALIZE_SESSION_METHOD = "KlarnaPaymentSessionFinalizationComponent.finalise(jsonData: String?)"
    
    // params
    static let CATEGORY_KEY = "category"
    static let CATEGORY_VALUE = "KLARNA"
    static let SESSION_TYPE_KEY = "sessionType"
    static let JSON_DATA_KEY = "jsonData (optional)"
    static let JSON_DATA_DEFAULT_VALUE = "None"
    static let AUTO_FINALIZE_KEY = "autoFinalize"
}
