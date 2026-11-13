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
    private var provider: PrimerKlarnaProviding?
    private let formKey: String
    private let onStatus: @MainActor (KlarnaWidgetStatus) -> Void
    private var reportedHeight: CGFloat = 0
    private let placeholderHeight: CGFloat = 88

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: reportedHeight > 0 ? reportedHeight : placeholderHeight)
    }

    init(
        clientToken: String,
        category: String,
        formKey: String,
        urlScheme: String?,
        onStatus: @escaping @MainActor (KlarnaWidgetStatus) -> Void
    ) {
        self.formKey = formKey
        self.onStatus = onStatus
        super.init(frame: .zero)

        let provider = PrimerKlarnaProvider(clientToken: clientToken, paymentCategory: category, urlScheme: urlScheme)
        provider.paymentViewDelegate = self
        provider.errorDelegate = self

        self.provider = provider
        KlarnaProviderStore.shared.set(provider, for: [formKey, category])

        provider.createPaymentView()
        provider.paymentView.map(embed(_:))
        provider.initializePaymentView()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { nil }

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

    private func report(_ status: KlarnaWidgetStatus) {
        Task { @MainActor in onStatus(status) }
    }
}

extension KlarnaWidgetContainerView: PrimerKlarnaProviderPaymentViewDelegate, PrimerKlarnaProviderErrorDelegate {
    func primerKlarnaWrapperInitialized() { provider?.loadPaymentView(jsonData: nil) }
    func primerKlarnaWrapperLoaded() { report(.ready(instanceId: formKey)) }
    func primerKlarnaWrapperReviewLoaded() {
        // The widget only shows the payment view, never Klarna's review screen
    }
    func primerKlarnaWrapperFailed(with error: PrimerKlarnaError) {
        logger.error(message: "klarna.widget failed: \(error.localizedDescription)")
        report(.failed(KlarnaWidgetError(code: error.errorId, message: error.localizedDescription)))
    }

    func primerKlarnaWrapperResized(to newHeight: CGFloat) {
        reportedHeight = newHeight
        invalidateIntrinsicContentSize()
    }
}
#endif
