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
                let urlScheme = (try? PrimerSettings.current.paymentMethodOptions.validUrlForUrlScheme())?.absoluteString
                return KlarnaWidgetContainerView(
                    clientToken: parsed?.clientToken ?? "",
                    category: parsed?.category ?? "",
                    urlScheme: urlScheme
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

    private final class KlarnaWidgetContainerView: UIView,
        PrimerKlarnaProviderPaymentViewDelegate,
        PrimerKlarnaProviderErrorDelegate {
        private var provider: PrimerKlarnaProviding?
        private var reportedHeight: CGFloat = 0
        private let placeholderHeight: CGFloat = 300

        override var intrinsicContentSize: CGSize {
            CGSize(width: UIView.noIntrinsicMetric, height: reportedHeight > 0 ? reportedHeight : placeholderHeight)
        }

        init(clientToken: String, category: String, urlScheme: String?) {
            super.init(frame: .zero)
            print("[KlarnaWidget] init — clientToken \(clientToken.isEmpty ? "EMPTY" : "present"), category '\(category)', urlScheme \(urlScheme ?? "nil")")

            let provider = PrimerKlarnaProvider(clientToken: clientToken, paymentCategory: category, urlScheme: urlScheme)
            provider.paymentViewDelegate = self
            provider.errorDelegate = self
            self.provider = provider

            provider.createPaymentView()
            if let paymentView = provider.paymentView {
                embed(paymentView)
                print("[KlarnaWidget] payment view created + embedded")
            } else {
                print("[KlarnaWidget] createPaymentView returned nil paymentView")
            }
            provider.initializePaymentView()
            print("[KlarnaWidget] initializePaymentView called")
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
        func primerKlarnaWrapperInitialized() {
            print("[KlarnaWidget] initialized → loadPaymentView")
            provider?.loadPaymentView(jsonData: nil)
        }
        func primerKlarnaWrapperLoaded() { print("[KlarnaWidget] loaded") }
        func primerKlarnaWrapperResized(to newHeight: CGFloat) {
            print("[KlarnaWidget] resized to \(newHeight)")
            reportedHeight = newHeight
            invalidateIntrinsicContentSize()
        }
        func primerKlarnaWrapperReviewLoaded() {}

        // MARK: - PrimerKlarnaProviderErrorDelegate
        func primerKlarnaWrapperFailed(with error: PrimerKlarnaError) {
            print("[KlarnaWidget] FAILED: \(error)")
        }
    }
#endif
