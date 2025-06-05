//
//  TokenizationProtocols.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 04.12.2023.
//

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
    func performPreTokenizationSteps() -> Promise<Void>
    func performPreTokenizationSteps() async throws
    func performTokenizationStep() -> Promise<Void>
    func performTokenizationStep() async throws
    func performPostTokenizationSteps() -> Promise<Void>
    func performPostTokenizationSteps() async throws
    func tokenize() -> Promise<PrimerPaymentMethodTokenData>
    func tokenize() async throws -> PrimerPaymentMethodTokenData
    func startTokenizationFlow() -> Promise<PrimerPaymentMethodTokenData>
    func startTokenizationFlow() async throws -> PrimerPaymentMethodTokenData
    func startPaymentFlow(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<PrimerCheckoutData?>
    func startPaymentFlow(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) async throws -> PrimerCheckoutData?
    func presentPaymentMethodUserInterface() -> Promise<Void>
    func presentPaymentMethodUserInterface() async throws
    func awaitUserInput() -> Promise<Void>
    func awaitUserInput() async throws

    func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken,
                                          paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<String?>
    func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken,
                                          paymentMethodTokenData: PrimerPaymentMethodTokenData) async throws -> String?
    func handleResumeStepsBasedOnSDKSettings(resumeToken: String) -> Promise<PrimerCheckoutData?>
    func handleResumeStepsBasedOnSDKSettings(resumeToken: String) async throws -> PrimerCheckoutData?
    func handleSuccessfulFlow()
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
