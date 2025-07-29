//
//  PrimerHeadlessKlarnaComponent+ViewHandling.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

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
    func createPaymentView() {
        klarnaProvider?.createPaymentView()
    }
    func removePaymentView() {
        klarnaProvider?.removePaymentView()
    }
    func initPaymentView() {
        klarnaProvider?.initializePaymentView()
    }
    func loadPaymentView(jsonData: String? = nil) {
        klarnaProvider?.loadPaymentView(jsonData: jsonData)
    }
}

// MARK: - Payment review
extension PrimerHeadlessKlarnaComponent {
    func loadPaymentReview() {
        klarnaProvider?.loadPaymentReview()
    }
}

#endif
