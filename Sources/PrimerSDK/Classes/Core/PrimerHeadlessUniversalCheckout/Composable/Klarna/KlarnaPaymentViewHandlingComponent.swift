//
//  KlarnaPaymentViewHandlingComponent.swift
//  PrimerSDK
//
//  Created by Illia Khrypunov on 06.11.2023.
//

import UIKit
import Foundation
import PrimerKlarnaSDK

public enum KlarnaPaymentViewHandling: PrimerHeadlessStep {
    case viewInitialized
    case viewResized(height: CGFloat)
    case viewLoaded
    case reviewLoaded
}

public class KlarnaPaymentViewHandlingComponent: PrimerHeadlessComponent {
    // MARK: - Provider
    private weak var klarnaProvider: PrimerKlarnaProviding?
    
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
        self.klarnaProvider?.createPaymentView()
        
        return self.klarnaProvider?.paymentView
    }
    
    func removePaymentView() {
        self.klarnaProvider?.removePaymentView()
    }
    
    func initPaymentView() {
        self.klarnaProvider?.initializePaymentView()
    }
    
    func loadPaymentView(jsonData: String? = nil) {
        self.klarnaProvider?.loadPaymentView(jsonData: jsonData)
    }
}

// MARK: - Payment review
public extension KlarnaPaymentViewHandlingComponent {
    func loadPaymentReview() {
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
