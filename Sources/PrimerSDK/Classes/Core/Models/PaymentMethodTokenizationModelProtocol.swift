//
//  PaymentMethodTokenizationModelProtocol.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
internal protocol PaymentMethodTokenizationModelProtocol: NSObject {
    var checkoutEventsNotifierModule: CheckoutEventsNotifierModule { get }

    // Events
    var didStartPayment: (() -> Void)? { get set }
    var didFinishPayment: ((Error?) -> Void)? { get set }

    var paymentMethodTokenData: PrimerPaymentMethodTokenData? { get set }
    var paymentCheckoutData: PrimerCheckoutData? { get set }
    var successMessage: String? { get set }

    func validate() throws
    func start()
    func performPreTokenizationSteps() async throws
    func performTokenizationStep() async throws
    func performPostTokenizationSteps() async throws
    func tokenize() async throws -> PrimerPaymentMethodTokenData
    func startTokenizationFlow() async throws -> PrimerPaymentMethodTokenData
    func startPaymentFlow(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) async throws -> PrimerCheckoutData?
    func presentPaymentMethodUserInterface() async throws
    func awaitUserInput() async throws
    func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken,
                                          paymentMethodTokenData: PrimerPaymentMethodTokenData) async throws -> String?
    func handleResumeStepsBasedOnSDKSettings(resumeToken: String) async throws -> PrimerCheckoutData?

    @MainActor
    func handleSuccessfulFlow()

    @MainActor
    func handleFailureFlow(errorMessage: String?)
    func cancel()
}

internal protocol PaymentMethodTokenizationViewProtocol: NSObject {
    var willPresentPaymentMethodUI: (() -> Void)? { get set }
    var didPresentPaymentMethodUI: (() -> Void)? { get set }
    var willDismissPaymentMethodUI: (() -> Void)? { get set }
    var didDismissPaymentMethodUI: (() -> Void)? { get set }

    // UI
    var config: PrimerPaymentMethod { get }
    var uiModule: UserInterfaceModule! { get }
    var position: Int { get set }
}
