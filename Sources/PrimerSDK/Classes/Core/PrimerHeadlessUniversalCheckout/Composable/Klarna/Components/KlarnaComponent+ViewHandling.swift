//
//  KlarnaComponent+ViewHandling.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 16.02.2024.
//

#if canImport(PrimerKlarnaSDK)
import UIKit
import PrimerKlarnaSDK

/**
 * Enumerates the steps involved in handling Klarna views during a payment session.
 * This enum represents various stages of Klarna view interactions within the payment process, including initialization, resizing, loading, and review stages.
 * It conforms to `PrimerHeadlessStep` to integrate with the broader Primer payment flow.
 *
 * Cases:
 *  - `viewInitialized`: Indicates that the Klarna view has been initialized. This is the first step in the Klarna view handling process.
 *  - `viewResized(height: CGFloat)`: Represents a change in the view's height, which may occur when the Klarna view adjusts to display different content. The `height` parameter specifies the new height of the view.
 *  - `viewLoaded`: Signifies that the Klarna view has finished loading its initial content and is ready for interaction.
 *  - `reviewLoaded`: Indicates that the reviewed information has been loaded into the Klarna view.
 */
public enum KlarnaViewHandlingStep: PrimerHeadlessStep {
    case viewInitialized
    case viewResized(height: CGFloat)
    case viewLoaded
    case reviewLoaded
}

extension KlarnaComponent {
    
    /// Sets Klarna provider payment view delegate
    func setPaymentViewDelegate() {
        klarnaProvider?.paymentViewDelegate = self
    }
}

// MARK: - PrimerKlarnaProviderPaymentViewDelegate
extension KlarnaComponent: PrimerKlarnaProviderPaymentViewDelegate {
    public func primerKlarnaWrapperInitialized() {
        stepDelegate?.didReceiveStep(step: KlarnaViewHandlingStep.viewInitialized)
    }
    
    public func primerKlarnaWrapperResized(to newHeight: CGFloat) {
        stepDelegate?.didReceiveStep(step: KlarnaViewHandlingStep.viewResized(height: newHeight))
    }
    
    public func primerKlarnaWrapperLoaded() {
        stepDelegate?.didReceiveStep(step: KlarnaViewHandlingStep.viewLoaded)
    }
    
    public func primerKlarnaWrapperReviewLoaded() {
        stepDelegate?.didReceiveStep(step: KlarnaViewHandlingStep.reviewLoaded)
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
