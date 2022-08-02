//
//  PaymentMethodTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 7/10/21.
//

#if canImport(UIKit)

import Foundation
import UIKit

typealias TokenizationCompletion = ((PrimerPaymentMethodTokenData?, Error?) -> Void)
typealias PaymentCompletion = ((PrimerCheckoutData?, Error?) -> Void)

internal protocol PaymentMethodTokenizationViewModelProtocol: NSObject {
    init(config: PrimerPaymentMethod)
    
    // UI
    var config: PrimerPaymentMethod { get set }
    var uiModule: UserInterfaceModule! { get }
    var position: Int { get set }
    
    // Events
    var didStartTokenization: (() -> Void)? { get set }
    var didFinishTokenization: ((Error?) -> Void)? { get set }
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
    
    func handleDecodedClientTokenIfNeeded(_ decodedClientToken: DecodedClientToken) -> Promise<String?>
    func handleResumeStepsBasedOnSDKSettings(resumeToken: String) -> Promise<PrimerCheckoutData?>
    func handleSuccessfulFlow()
    func handleFailureFlow(errorMessage: String?)
    func submitButtonTapped()
}

internal protocol SearchableItemsPaymentMethodTokenizationViewModelProtocol {
    func cancel()
    var tableView: UITableView { get set }
    var searchCountryTextField: PrimerSearchTextField { get set }
    var config: PrimerPaymentMethod { get set }
}

class PaymentMethodTokenizationViewModel: NSObject, PaymentMethodTokenizationViewModelProtocol {

    var config: PrimerPaymentMethod
    
    // Events
    var didStartTokenization: (() -> Void)?
    var didFinishTokenization: ((Error?) -> Void)?
    var didStartPayment: (() -> Void)?
    var didFinishPayment: ((Error?) -> Void)?
    var willPresentPaymentMethodUI: (() -> Void)?
    var didPresentPaymentMethodUI: (() -> Void)?
    var willDismissPaymentMethodUI: (() -> Void)?
    var didDismissPaymentMethodUI: (() -> Void)?
    
    var paymentMethodTokenData: PrimerPaymentMethodTokenData?
    var paymentCheckoutData: PrimerCheckoutData?
    var successMessage: String?
    
    var resumePaymentId: String?
    
    var position: Int = 0
    var uiModule: UserInterfaceModule!
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    required init(config: PrimerPaymentMethod) {
        self.config = config
        super.init()
        self.uiModule = UserInterfaceModule(paymentMethodTokenizationViewModel: self)
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
            firstly {
                self.performPreTokenizationSteps()
            }
            .then { () -> Promise<Void> in
                return self.performTokenizationStep()
            }
            .then { () -> Promise<Void> in
                return self.performPostTokenizationSteps()
            }
            .done {
                seal.fulfill(self.paymentMethodTokenData!)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    func presentPaymentMethodUserInterface() -> Promise<Void> {
        fatalError("\(#function) must be overriden")
    }
    
    func awaitUserInput() -> Promise<Void> {
        fatalError("\(#function) must be overriden")
    }
    
    func handleDecodedClientTokenIfNeeded(_ decodedClientToken: DecodedClientToken) -> Promise<String?> {
        fatalError("\(#function) must be overriden")
    }
    
    func submitButtonTapped() {
        fatalError("\(#function) must be overriden")
    }
}

#endif
