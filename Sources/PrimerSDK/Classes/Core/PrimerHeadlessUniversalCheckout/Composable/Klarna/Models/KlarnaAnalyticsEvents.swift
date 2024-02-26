//
//  KlarnaAnalyticsEvents.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 26.01.2024.
//

import Foundation

struct KlarnaAnalyticsEvents {
    // session creation component
    static let createSessionUpdateCollectedDataMethod = "KlarnaPaymentSessionCreationComponent.updateCollectedData()"
    static let createSessionStartMethod = "KlarnaPaymentSessionCreationComponent.start()"
    // view handling component
    static let createPaymentViewMethod = "KlarnaPaymentViewHandlingComponent.createPaymentView()"
    static let removePaymentViewMethod = "KlarnaPaymentViewHandlingComponent.removePaymentView()"
    static let initPaymentViewMethod = "KlarnaPaymentViewHandlingComponent.initPaymentView()"
    static let loadPaymentViewMethod = "KlarnaPaymentViewHandlingComponent.loadPaymentView(jsonData: String?)"
    static let loadPaymentReviewMethod = "KlarnaPaymentViewHandlingComponent.loadPaymentReview(jsonData: String?)"
    // session authorization component
    static let authorizeSessionMethod = "KlarnaPaymentSessionAuthorizationComponent.authorizeSession(autoFinalize: Bool, jsonData: String?)"
    static let reauthorizeSessionMethod = "KlarnaPaymentSessionAuthorizationComponent.reauthorizeSession(jsonData: String?)"
    // session finalization component
    static let finalizeSessionMethod = "KlarnaPaymentSessionFinalizationComponent.finalise(jsonData: String?)"
    // params
    static let categoryKey = "category"
    static let categoryValue = "KLARNA"
    static let sessionTypeKey = "sessionType"
    static let jsonDataKey = "jsonData (optional)"
    static let jsonDataDefaultValue = "None"
    static let autoFinalizeKey = "autoFinalize"
}
