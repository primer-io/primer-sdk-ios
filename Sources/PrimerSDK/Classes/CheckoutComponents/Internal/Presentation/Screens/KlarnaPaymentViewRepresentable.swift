//
//  KlarnaPaymentViewRepresentable.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import UIKit

/// UIViewRepresentable wrapper for the Klarna SDK's native UIView.
@available(iOS 15.0, *)
struct KlarnaPaymentViewRepresentable: UIViewRepresentable {

    let paymentView: UIView

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        embedPaymentView(in: container)
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Check if the payment view has changed (e.g., after switching categories)
        guard paymentView.superview !== uiView else { return }

        // Remove old subviews and embed the new payment view
        uiView.subviews.forEach { $0.removeFromSuperview() }
        embedPaymentView(in: uiView)
    }

    private func embedPaymentView(in container: UIView) {
        paymentView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(paymentView)

        NSLayoutConstraint.activate([
            paymentView.topAnchor.constraint(equalTo: container.topAnchor),
            paymentView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            paymentView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            paymentView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }
}
