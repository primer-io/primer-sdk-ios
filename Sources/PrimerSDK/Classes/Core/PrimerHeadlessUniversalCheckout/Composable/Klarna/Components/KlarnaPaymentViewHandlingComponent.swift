//
//  KlarnaPaymentViewHandlingComponent.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 26.01.2024.
//

#if canImport(PrimerKlarnaSDK)
import UIKit
import Foundation
import PrimerKlarnaSDK

public enum KlarnaPaymentViewHandling: PrimerHeadlessStep {
    case viewInitialized
    case viewResized(height: CGFloat)
    case viewLoaded
    case reviewLoaded
}

public class KlarnaPaymentViewHandlingComponent: PrimerHeadlessAnalyticsRecordable {
    // MARK: - Provider
    private(set) weak var klarnaProvider: PrimerKlarnaProviding?
    
    // MARK: - Delegates
    public weak var stepDelegate: PrimerHeadlessSteppableDelegate?
    
    // MARK: - Set
    func setProvider(provider: PrimerKlarnaProviding?) {
        klarnaProvider = provider
        klarnaProvider?.paymentViewDelegate = self
    }
}

// MARK: - Payment view
public extension KlarnaPaymentViewHandlingComponent {
    func createPaymentView() -> UIView? {
        recordPaymentViewEvent(name: KlarnaAnalyticsEvents.CREATE_PAYMENT_VIEW_METHOD)
        klarnaProvider?.createPaymentView()
        
        return klarnaProvider?.paymentView
    }
    
    func removePaymentView() {
        recordPaymentViewEvent(name: KlarnaAnalyticsEvents.REMOVE_PAYMENT_VIEW_METHOD)
        klarnaProvider?.removePaymentView()
    }
    
    func initPaymentView() {
        recordPaymentViewEvent(name: KlarnaAnalyticsEvents.INIT_PAYMENT_VIEW_METHOD)
        klarnaProvider?.initializePaymentView()
    }
    
    func loadPaymentView(jsonData: String? = nil) {
        recordPaymentViewEvent(name: KlarnaAnalyticsEvents.LOAD_PAYMENT_VIEW_METHOD, jsonData: jsonData ?? KlarnaAnalyticsEvents.JSON_DATA_DEFAULT_VALUE)
        klarnaProvider?.loadPaymentView(jsonData: jsonData)
    }
}

// MARK: - Payment review
public extension KlarnaPaymentViewHandlingComponent {
    func loadPaymentReview() {
        recordPaymentViewEvent(name: KlarnaAnalyticsEvents.LOAD_PAYMENT_REVIEW_METHOD)
        klarnaProvider?.loadPaymentReview()
    }
}

// MARK: - PrimerKlarnaProviderPaymentViewDelegate
extension KlarnaPaymentViewHandlingComponent: PrimerKlarnaProviderPaymentViewDelegate {
    public func primerKlarnaWrapperInitialized() {
        stepDelegate?.didReceiveStep(step: KlarnaPaymentViewHandling.viewInitialized)
    }
    
    public func primerKlarnaWrapperResized(to newHeight: CGFloat) {
        stepDelegate?.didReceiveStep(step: KlarnaPaymentViewHandling.viewResized(height: newHeight))
    }
    
    public func primerKlarnaWrapperLoaded() {
        stepDelegate?.didReceiveStep(step: KlarnaPaymentViewHandling.viewLoaded)
    }
    
    public func primerKlarnaWrapperReviewLoaded() {
        stepDelegate?.didReceiveStep(step: KlarnaPaymentViewHandling.reviewLoaded)
    }
}

// MARK: - Helpers
extension KlarnaPaymentViewHandlingComponent {
    private func recordPaymentViewEvent(name: String, jsonData: String? = nil) {
        var params = [KlarnaAnalyticsEvents.CATEGORY_KEY: KlarnaAnalyticsEvents.CATEGORY_VALUE]
        
        if let jsonData {
            params[KlarnaAnalyticsEvents.JSON_DATA_KEY] = jsonData
        }
        
        recordEvent(
            type: .sdkEvent,
            name: name,
            params: params
        )
    }
}
#endif

