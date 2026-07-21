//
//  KlarnaWidgetContainerView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit
#if canImport(PrimerKlarnaSDK)
import PrimerKlarnaSDK

final class KlarnaWidgetContainerView: UIView {
    private var provider: PrimerKlarnaProviding?
    private var reportedHeight: CGFloat = 0
    private let placeholderHeight: CGFloat = 88
    
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: reportedHeight > 0 ? reportedHeight : placeholderHeight)
    }
    
    init(clientToken: String, category: String, urlScheme: String?) {
        super.init(frame: .zero)
        
        let provider = PrimerKlarnaProvider(clientToken: clientToken, paymentCategory: category, urlScheme: urlScheme)
        provider.paymentViewDelegate = self
        provider.errorDelegate = self
        
        self.provider = provider
        KlarnaProviderStore.shared.set(provider, for: category)
        
        provider.createPaymentView()
        provider.paymentView.map(embed(_:))
        provider.initializePaymentView()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func embed(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor),
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}

extension KlarnaWidgetContainerView: PrimerKlarnaProviderPaymentViewDelegate, PrimerKlarnaProviderErrorDelegate {
    
    func primerKlarnaWrapperLoaded() {}
    func primerKlarnaWrapperReviewLoaded() {}
    func primerKlarnaWrapperFailed(with error: PrimerKlarnaError) {}
    
    func primerKlarnaWrapperInitialized() { provider?.loadPaymentView(jsonData: nil) }
    func primerKlarnaWrapperResized(to newHeight: CGFloat) {
        reportedHeight = newHeight
        invalidateIntrinsicContentSize()
    }

}
#endif
