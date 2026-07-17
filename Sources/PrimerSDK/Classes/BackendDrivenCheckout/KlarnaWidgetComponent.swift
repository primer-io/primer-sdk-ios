//
//  KlarnaWidgetComponent.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerBDCUI

enum KlarnaWidgetComponent {
    static func register() {
        #if canImport(PrimerKlarnaSDK)
            SDUIComponentRegistry.shared.register("klarna.widget") { props in
                let parsed = try? props?.casted(to: KlarnaWidgetProps.self)
                return KlarnaWidgetContainerView(
                    clientToken: parsed?.clientToken ?? "",
                    category: parsed?.category ?? ""
                )
            }
        #endif
    }
}

#if canImport(PrimerKlarnaSDK)
    import PrimerKlarnaSDK
    import UIKit

    private struct KlarnaWidgetProps: Decodable {
        let clientToken: String?
        let category: String?
    }

    private final class KlarnaWidgetContainerView: UIView, PrimerKlarnaProviderPaymentViewDelegate {
        private var provider: PrimerKlarnaProviding?
        private var reportedHeight: CGFloat = 0
        private let placeholderHeight: CGFloat = 300

        override var intrinsicContentSize: CGSize {
            CGSize(width: UIView.noIntrinsicMetric, height: reportedHeight > 0 ? reportedHeight : placeholderHeight)
        }

        init(clientToken: String, category: String) {
            super.init(frame: .zero)

            let provider = PrimerKlarnaProvider(clientToken: clientToken, paymentCategory: category)
            provider.paymentViewDelegate = self
            self.provider = provider

            provider.createPaymentView()
            if let paymentView = provider.paymentView {
                embed(paymentView)
            }
            // TODO: pass the merchant's URL scheme so Klarna app-switch redirects return.
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

        // MARK: - PrimerKlarnaProviderPaymentViewDelegate
        func primerKlarnaWrapperInitialized() { provider?.loadPaymentView(jsonData: nil) }
        func primerKlarnaWrapperLoaded() {}
        func primerKlarnaWrapperResized(to newHeight: CGFloat) {
            reportedHeight = newHeight
            invalidateIntrinsicContentSize()
        }
        func primerKlarnaWrapperReviewLoaded() {}
    }
#endif
