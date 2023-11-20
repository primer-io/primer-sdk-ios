//
//  PaymentMethodTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 7/10/21.
//

import Foundation
import UIKit

typealias TokenizationCompletion = ((PrimerPaymentMethodTokenData?, Error?) -> Void)
typealias PaymentCompletion = ((PrimerCheckoutData?, Error?) -> Void)

internal protocol PaymentMethodTokenizationViewModelProtocol: NSObject {

    static var apiClient: PrimerAPIClientProtocol? { get set }

    init(config: PrimerPaymentMethod)

    // UI
    var config: PrimerPaymentMethod! { get set }
    var uiModule: UserInterfaceModule! { get }
    var position: Int { get set }

    // Events
    var checkouEventsNotifierModule: CheckoutEventsNotifierModule { get }
    var didStartPayment: (() -> Void)? { get set }
    var didFinishPayment: ((Error?) -> Void)? { get set }
    var willPresentPaymentMethodUI: (() -> Void)? { get set }
    var didPresentPaymentMethodUI: (() -> Void)? { get set }
    var willDismissPaymentMethodUI: (() -> Void)? { get set }
    var didDismissPaymentMethodUI: (() -> Void)? { get set }

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
    func submitButtonTapped()

    func cancel()
}

internal protocol SearchableItemsPaymentMethodTokenizationViewModelProtocol {

    var tableView: UITableView { get set }
    var searchableTextField: PrimerSearchTextField { get set }
    var config: PrimerPaymentMethod! { get set }

    func cancel()
}

class PaymentMethodTokenizationViewModel: NSObject, PaymentMethodTokenizationViewModelProtocol, LogReporter {

    var config: PrimerPaymentMethod!
    static var apiClient: PrimerAPIClientProtocol?

    // Events
    let checkouEventsNotifierModule = CheckoutEventsNotifierModule()
    var didStartPayment: (() -> Void)?
    var didFinishPayment: ((Error?) -> Void)?
    var willPresentPaymentMethodUI: (() -> Void)?
    var didPresentPaymentMethodUI: (() -> Void)?
    var willDismissPaymentMethodUI: (() -> Void)?
    var didDismissPaymentMethodUI: (() -> Void)?
    var didCancel: (() -> Void)?
    var isCancelled: Bool = false
    var paymentMethodTokenData: PrimerPaymentMethodTokenData?
    var paymentCheckoutData: PrimerCheckoutData?
    var successMessage: String?
    var resumePaymentId: String?
    var position: Int = 0
    var uiModule: UserInterfaceModule!

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    required init(config: PrimerPaymentMethod) {
        self.config = config
        super.init()
        self.uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: self)
    }

    @objc
    func receivedNotification(_ notification: Notification) {
        // Use it to handle notifications that apply on tokenization view models.
    }

    @objc
    func validate() throws {
        fatalError("\(#function) must be overriden")
    }

    func performPreTokenizationSteps() -> Promise<Void> {
        fatalError("\(#function) must be overriden")
    }

    func performTokenizationStep() -> Promise<Void> {
        fatalError("\(#function) must be overriden")
    }

    func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        fatalError("\(#function) must be overriden")
    }

    func performPostTokenizationSteps() -> Promise<Void> {
        fatalError("\(#function) must be overriden")
    }

    func startTokenizationFlow() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            var cancelledError: PrimerError?
            self.didCancel = {
                self.isCancelled = true
                cancelledError = PrimerError.cancelled(paymentMethodType: self.config.type, userInfo: nil, diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: cancelledError!)
                seal.reject(cancelledError!)
                self.isCancelled = false
            }

            firstly { () -> Promise<Void> in
                if let cancelledError = cancelledError {
                    throw cancelledError
                }
                return self.performPreTokenizationSteps()
            }
            .then { () -> Promise<Void> in
                if let cancelledError = cancelledError {
                    throw cancelledError
                }
                return self.performTokenizationStep()
            }
            .then { () -> Promise<Void> in
                if let cancelledError = cancelledError {
                    throw cancelledError
                }
                return self.performPostTokenizationSteps()
            }
            .done {
                if let cancelledError = cancelledError {
                    throw cancelledError
                }
                seal.fulfill(self.paymentMethodTokenData!)
            }
            .catch { err in
                if cancelledError == nil {
                    seal.reject(err)
                } else {
                    // Cancelled error has already been thrown
                }
            }
        }
    }

    func handleSuccessfulFlow() {
        PrimerUIManager.dismissOrShowResultScreen(type: .success, withMessage: self.successMessage)
    }

    func presentPaymentMethodUserInterface() -> Promise<Void> {
        fatalError("\(#function) must be overriden")
    }

    func awaitUserInput() -> Promise<Void> {
        fatalError("\(#function) must be overriden")
    }

    func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken) -> Promise<String?> {
        fatalError("\(#function) must be overriden")
    }

    func submitButtonTapped() {
        fatalError("\(#function) must be overriden")
    }

    func cancel() {
        self.didCancel?()
    }
}
