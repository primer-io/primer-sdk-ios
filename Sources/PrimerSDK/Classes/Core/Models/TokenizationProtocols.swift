//
//  TokenizationProtocols.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 04.12.2023.
//

import Foundation
internal protocol PaymentMethodTokenizationModelProtocol: NSObject {
    static var apiClient: PrimerAPIClientProtocol? { get set }

    init(config: PrimerPaymentMethod, uiManager: PrimerUIManaging)
    var checkouEventsNotifierModule: CheckoutEventsNotifierModule { get }

    // Events
    var didStartPayment: (() -> Void)? { get set }
    var didFinishPayment: ((Error?) -> Void)? { get set }

    var paymentMethodTokenData: PrimerPaymentMethodTokenData? { get set }
    var paymentCheckoutData: PrimerCheckoutData? { get set }
    var successMessage: String? { get set }

    func validate() throws
    func start()
    func performPreTokenizationSteps() -> Promise<Void>
    func performTokenizationStep() -> Promise<Void>
    func performPostTokenizationSteps() -> Promise<Void>
    func tokenize() -> Promise<PrimerPaymentMethodTokenData>
    func startTokenizationFlow() -> Promise<PrimerPaymentMethodTokenData>
    func startPaymentFlow(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<PrimerCheckoutData?>
    func presentPaymentMethodUserInterface() -> Promise<Void>
    func awaitUserInput() -> Promise<Void>

    func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken) -> Promise<String?>
    func handleResumeStepsBasedOnSDKSettings(resumeToken: String) -> Promise<PrimerCheckoutData?>
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
