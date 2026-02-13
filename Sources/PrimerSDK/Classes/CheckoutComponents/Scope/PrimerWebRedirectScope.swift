//
//  PrimerWebRedirectScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
public typealias WebRedirectScreenComponent = (any PrimerWebRedirectScope) -> any View

@available(iOS 15.0, *)
public typealias WebRedirectButtonComponent = (any PrimerWebRedirectScope) -> any View

@available(iOS 15.0, *)
@MainActor
public protocol PrimerWebRedirectScope: PrimerPaymentMethodScope where State == WebRedirectState {
    var paymentMethodType: String { get }
    var state: AsyncStream<WebRedirectState> { get }
    var presentationContext: PresentationContext { get }
    var dismissalMechanism: [DismissalMechanism] { get }

    // MARK: - Payment Method Lifecycle

    func start()
    func submit()
    func cancel()

    // MARK: - Navigation Methods

    func onBack()
    func onCancel()

    // MARK: - Screen-Level Customization

    var screen: WebRedirectScreenComponent? { get set }
    var payButton: WebRedirectButtonComponent? { get set }
    var submitButtonText: String? { get set }
}
