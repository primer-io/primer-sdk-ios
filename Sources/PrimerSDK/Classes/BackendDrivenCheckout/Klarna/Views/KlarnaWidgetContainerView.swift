//
//  KlarnaWidgetContainerView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if canImport(PrimerKlarnaSDK)
@_spi(PrimerInternal) import PrimerFoundation
import PrimerKlarnaSDK
import UIKit

final class KlarnaWidgetContainerView: UIView, LogReporter {
    let category: String
    private(set) var provider: PrimerKlarnaProviding?
    private let onReady: @MainActor () -> Void
    private var loadContinuation: CheckedContinuation<Bool, Never>?
    private var reportedHeight: CGFloat = 0
    private let placeholderHeight: CGFloat = 88

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: reportedHeight > 0 ? reportedHeight : placeholderHeight)
    }

    init(clientToken: String, category: String, urlScheme: String?, onReady: @escaping @MainActor () -> Void) {
        self.category = category
        self.onReady = onReady
        super.init(frame: .zero)

        let provider = PrimerKlarnaProvider(clientToken: clientToken, paymentCategory: category, urlScheme: urlScheme)
        provider.paymentViewDelegate = self
        provider.errorDelegate = self

        self.provider = provider
        KlarnaWidgetStore.shared.set(self, for: category)

        provider.createPaymentView()
        provider.paymentView.map(embed(_:))
        provider.initializePaymentView()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { nil }

    func load() async -> Bool {
        await withCheckedContinuation { continuation in
            loadContinuation = continuation
            provider?.loadPaymentView(jsonData: nil)
        }
    }

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
    func primerKlarnaWrapperInitialized() { Task { @MainActor in onReady() } }
    func primerKlarnaWrapperLoaded() { finishLoad(loaded: true) }
    func primerKlarnaWrapperReviewLoaded() {
        // The widget only shows the payment view, never Klarna's review screen
    }
    func primerKlarnaWrapperFailed(with error: PrimerKlarnaError) {
        logger.error(message: "klarna.widget failed: \(error.localizedDescription)")
        finishLoad(loaded: false)
    }

    func primerKlarnaWrapperResized(to newHeight: CGFloat) {
        reportedHeight = newHeight
        invalidateIntrinsicContentSize()
    }

    private func finishLoad(loaded: Bool) {
        loadContinuation?.resume(returning: loaded)
        loadContinuation = nil
    }
}
#endif
