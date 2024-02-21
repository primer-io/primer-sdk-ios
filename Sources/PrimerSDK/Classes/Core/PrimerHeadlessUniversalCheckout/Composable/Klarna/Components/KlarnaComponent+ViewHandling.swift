//
//  KlarnaComponent+ViewHandling.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 16.02.2024.
//

#if canImport(PrimerKlarnaSDK)
import UIKit
import PrimerKlarnaSDK

extension KlarnaComponent {
    
    /// Sets Klarna provider payment view delegate
    func setPaymentViewDelegate() {
        klarnaProvider?.paymentViewDelegate = self
    }
}

// MARK: - PrimerKlarnaProviderPaymentViewDelegate
extension KlarnaComponent: PrimerKlarnaProviderPaymentViewDelegate {
    public func primerKlarnaWrapperInitialized() {
        stepDelegate?.didReceiveStep(step: KlarnaStep.viewInitialized)
    }
    
    public func primerKlarnaWrapperResized(to newHeight: CGFloat) {
        stepDelegate?.didReceiveStep(step: KlarnaStep.viewResized(height: newHeight))
    }
    
    public func primerKlarnaWrapperLoaded() {
        stepDelegate?.didReceiveStep(step: KlarnaStep.viewLoaded)
    }
    
    public func primerKlarnaWrapperReviewLoaded() {
        stepDelegate?.didReceiveStep(step: KlarnaStep.reviewLoaded)
    }
}

// MARK: - Payment view
extension KlarnaComponent {
    public func createPaymentView() -> UIView? {
        recordPaymentViewEvent(name: KlarnaAnalyticsEvents.CREATE_PAYMENT_VIEW_METHOD)
        klarnaProvider?.createPaymentView()
        
        return klarnaProvider?.paymentView
    }
    
    public func removePaymentView() {
        recordPaymentViewEvent(name: KlarnaAnalyticsEvents.REMOVE_PAYMENT_VIEW_METHOD)
        klarnaProvider?.removePaymentView()
    }
    
    public func initPaymentView() {
        recordPaymentViewEvent(name: KlarnaAnalyticsEvents.INIT_PAYMENT_VIEW_METHOD)
        klarnaProvider?.initializePaymentView()
    }
    
    public func loadPaymentView(jsonData: String? = nil) {
        recordPaymentViewEvent(name: KlarnaAnalyticsEvents.LOAD_PAYMENT_VIEW_METHOD, jsonData: jsonData ?? KlarnaAnalyticsEvents.JSON_DATA_DEFAULT_VALUE)
        klarnaProvider?.loadPaymentView(jsonData: jsonData)
    }
}

// MARK: - Payment review
extension KlarnaComponent {
    public func loadPaymentReview() {
        recordPaymentViewEvent(name: KlarnaAnalyticsEvents.LOAD_PAYMENT_REVIEW_METHOD)
        klarnaProvider?.loadPaymentReview()
    }
}

#endif
