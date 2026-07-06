//
//  DemoCheckout.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

extension View {
    /// Wires an inline ``PrimerCheckoutSession`` and surfaces its terminal outcome as an alert that
    /// dismisses the demo — the minimal completion handling most inline demos need.
    @available(iOS 15.0, *)
    func demoCheckout(_ session: PrimerCheckoutSession) -> some View {
        modifier(DemoCheckoutModifier(session: session))
    }
}

@available(iOS 15.0, *)
private struct DemoCheckoutModifier: ViewModifier {
    let session: PrimerCheckoutSession
    @SwiftUI.Environment(\.dismiss) private var dismiss
    @State private var result: DemoCheckoutResult?

    func body(content: Content) -> some View {
        content
            .primerCheckoutSession(session) { result = DemoCheckoutResult($0) }
            .alert(result?.title ?? "", isPresented: presented, presenting: result) { _ in
                Button("Done") { dismiss() }
            } message: { Text($0.message) }
    }

    private var presented: Binding<Bool> {
        Binding(get: { result != nil }, set: { if !$0 { result = nil } })
    }
}

/// A terminal checkout outcome rendered as an alert. `nil` for non-terminal states.
@available(iOS 15.0, *)
private struct DemoCheckoutResult {
    let title: String
    let message: String

    init?(_ state: PrimerCheckoutState) {
        switch state {
        case let .success(result):
            title = "Payment complete"
            message = "Payment \(result.paymentId) succeeded."
        case let .failure(error):
            title = "Payment failed"
            message = error.localizedDescription
        default:
            return nil
        }
    }
}
