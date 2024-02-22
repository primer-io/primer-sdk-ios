//
//  KlarnaComponent+ViewHandling.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 16.02.2024.
//

#if canImport(PrimerKlarnaSDK)
import UIKit
import PrimerKlarnaSDK

extension PrimerHeadlessKlarnaComponent {
    
    /// Sets Klarna provider payment view delegate
    func setPaymentViewDelegate() {
        klarnaProvider?.paymentViewDelegate = self
    }
}

// MARK: - PrimerKlarnaProviderPaymentViewDelegate
extension PrimerHeadlessKlarnaComponent: PrimerKlarnaProviderPaymentViewDelegate {
    public func primerKlarnaWrapperInitialized() {
        loadPaymentView()
        stepDelegate?.didReceiveStep(step: KlarnaStep.viewInitialized)
    }
    
    public func primerKlarnaWrapperResized(to newHeight: CGFloat) {
        stepDelegate?.didReceiveStep(step: KlarnaStep.viewResized(height: newHeight))
    }
    
    public func primerKlarnaWrapperLoaded() {
        stepDelegate?.didReceiveStep(step: KlarnaStep.viewLoaded(view: klarnaProvider?.paymentView))
    }
    
    public func primerKlarnaWrapperReviewLoaded() {
        stepDelegate?.didReceiveStep(step: KlarnaStep.reviewLoaded)
    }
}

// MARK: - Payment view
extension PrimerHeadlessKlarnaComponent {
    public func createPaymentView() {
        recordPaymentViewEvent(name: KlarnaAnalyticsEvents.CREATE_PAYMENT_VIEW_METHOD)
        klarnaProvider?.createPaymentView()
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
extension PrimerHeadlessKlarnaComponent {
    public func loadPaymentReview() {
        recordPaymentViewEvent(name: KlarnaAnalyticsEvents.LOAD_PAYMENT_REVIEW_METHOD)
        klarnaProvider?.loadPaymentReview()
    }
}

#endif
