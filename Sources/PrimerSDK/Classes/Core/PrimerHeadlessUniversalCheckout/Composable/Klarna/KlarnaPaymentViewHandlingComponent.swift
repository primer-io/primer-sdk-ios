//
//  KlarnaPaymentViewHandlingComponent.swift
//  PrimerSDK
//
//  Created by Illia Khrypunov on 06.11.2023.
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

public class KlarnaPaymentViewHandlingComponent: PrimerHeadlessComponent, PrimerHeadlessAnalyticsRecordable {
    // MARK: - Provider
    private(set) weak var klarnaProvider: PrimerKlarnaProviding?
    
    // MARK: - Delegates
    public weak var stepDelegate: PrimerHeadlessSteppableDelegate?
    
    // MARK: - Set
    func setProvider(provider: PrimerKlarnaProviding?) {
        self.klarnaProvider = provider
        self.klarnaProvider?.paymentViewDelegate = self
    }
}

// MARK: - Payment view
public extension KlarnaPaymentViewHandlingComponent {
    func createPaymentView() -> UIView? {
        self.recordEvent(
            type: .sdkEvent,
            name: KlarnaAnalyticsEvents.CREATE_PAYMENT_VIEW_METHOD,
            params: [
                KlarnaAnalyticsEvents.CATEGORY_KEY: KlarnaAnalyticsEvents.CATEGORY_VALUE
            ]
        )
        
        self.klarnaProvider?.createPaymentView()
        
        return self.klarnaProvider?.paymentView
    }
    
    func removePaymentView() {
        self.recordEvent(
            type: .sdkEvent,
            name: KlarnaAnalyticsEvents.REMOVE_PAYMENT_VIEW_METHOD,
            params: [
                KlarnaAnalyticsEvents.CATEGORY_KEY: KlarnaAnalyticsEvents.CATEGORY_VALUE
            ]
        )
        
        self.klarnaProvider?.removePaymentView()
    }
    
    func initPaymentView() {
        self.recordEvent(
            type: .sdkEvent,
            name: KlarnaAnalyticsEvents.INIT_PAYMENT_VIEW_METHOD,
            params: [
                KlarnaAnalyticsEvents.CATEGORY_KEY: KlarnaAnalyticsEvents.CATEGORY_VALUE
            ]
        )
        
        self.klarnaProvider?.initializePaymentView()
    }
    
    func loadPaymentView(jsonData: String? = nil) {
        self.recordEvent(
            type: .sdkEvent,
            name: KlarnaAnalyticsEvents.LOAD_PAYMENT_VIEW_METHOD,
            params: [
                KlarnaAnalyticsEvents.CATEGORY_KEY: KlarnaAnalyticsEvents.CATEGORY_VALUE,
                KlarnaAnalyticsEvents.JSON_DATA_KEY: jsonData ?? KlarnaAnalyticsEvents.JSON_DATA_DEFAULT_VALUE
            ]
        )
        
        self.klarnaProvider?.loadPaymentView(jsonData: jsonData)
    }
}

// MARK: - Payment review
public extension KlarnaPaymentViewHandlingComponent {
    func loadPaymentReview() {
        self.recordEvent(
            type: .sdkEvent,
            name: KlarnaAnalyticsEvents.LOAD_PAYMENT_VIEW_METHOD,
            params: [
                KlarnaAnalyticsEvents.CATEGORY_KEY: KlarnaAnalyticsEvents.CATEGORY_VALUE
            ]
        )
        
        self.klarnaProvider?.loadPaymentReview()
    }
}

// MARK: - PrimerKlarnaProviderPaymentViewDelegate
extension KlarnaPaymentViewHandlingComponent: PrimerKlarnaProviderPaymentViewDelegate {
    public func primerKlarnaWrapperInitialized() {
        self.stepDelegate?.didReceiveStep(step: KlarnaPaymentViewHandling.viewInitialized)
    }
    
    public func primerKlarnaWrapperResized(to newHeight: CGFloat) {
        self.stepDelegate?.didReceiveStep(step: KlarnaPaymentViewHandling.viewResized(height: newHeight))
    }
    
    public func primerKlarnaWrapperLoaded() {
        self.stepDelegate?.didReceiveStep(step: KlarnaPaymentViewHandling.viewLoaded)
    }
    
    public func primerKlarnaWrapperReviewLoaded() {
        self.stepDelegate?.didReceiveStep(step: KlarnaPaymentViewHandling.reviewLoaded)
    }
}
#endif
