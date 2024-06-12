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

// swiftlint:disable type_name
internal protocol PaymentMethodTokenizationViewModelProtocol: PaymentMethodTokenizationModelProtocol, PaymentMethodTokenizationViewProtocol {
    func submitButtonTapped()
}

internal protocol SearchableItemsPaymentMethodTokenizationViewModelProtocol {
    // swiftlint:enable type_name

    var tableView: UITableView { get set }
    var searchableTextField: PrimerSearchTextField { get set }
    var config: PrimerPaymentMethod { get }

    func cancel()
}

class PaymentMethodTokenizationViewModel: NSObject, PaymentMethodTokenizationViewModelProtocol, LogReporter {

    // Events
    let checkoutEventsNotifierModule = CheckoutEventsNotifierModule()
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

    let config: PrimerPaymentMethod

    let uiManager: PrimerUIManaging

    let tokenizationService: TokenizationServiceProtocol

    let createResumePaymentService: CreateResumePaymentServiceProtocol

    convenience init(config: PrimerPaymentMethod,
                     apiClient: PrimerAPIClientProtocol = PrimerAPIClient()) {
        self.init(config: config,
                  uiManager: PrimerUIManager.shared,
                  tokenizationService: TokenizationService(apiClient: apiClient),
                  createResumePaymentService: CreateResumePaymentService(paymentMethodType: config.type,
                                                                         apiClient: apiClient)
        )
    }

    init(config: PrimerPaymentMethod,
         uiManager: PrimerUIManaging,
         tokenizationService: TokenizationServiceProtocol,
         createResumePaymentService: CreateResumePaymentServiceProtocol) {
        self.config = config
        self.uiManager = uiManager
        self.tokenizationService = tokenizationService
        self.createResumePaymentService = createResumePaymentService
        super.init()
        self.uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: self)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    func receivedNotification(_ notification: Notification) {
        // Override to handle notifications that are relevant tokenization view models.
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
                cancelledError = PrimerError.cancelled(paymentMethodType: self.config.type, userInfo: .errorUserInfoDictionary(),
                                                       diagnosticsId: UUID().uuidString)
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
        let categories = self.config.paymentMethodManagerCategories
        PrimerUIManager.dismissOrShowResultScreen(type: .success,
                                                  paymentMethodManagerCategories: categories ?? [],
                                                  withMessage: self.successMessage)
    }

    func presentPaymentMethodUserInterface() -> Promise<Void> {
        fatalError("\(#function) must be overriden")
    }

    func awaitUserInput() -> Promise<Void> {
        fatalError("\(#function) must be overriden")
    }

    func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken,
                                          paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<String?> {
        fatalError("\(#function) must be overriden")
    }

    func submitButtonTapped() {
        fatalError("\(#function) must be overriden")
    }

    func cancel() {
        self.didCancel?()
    }
}
