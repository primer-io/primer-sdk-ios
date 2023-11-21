//
//  BankSelectorTokenizationModel.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 16.11.2023.
//

import Foundation
protocol BankSelectorTokenizationDelegate {
    var paymentMethodType: PrimerPaymentMethodType { get set }
    var didFinishPayment: ((Error?) -> Void)? { get set }
    var willPresentPaymentMethodUI: (() -> Void)? { get set }
    var didPresentPaymentMethodUI: (() -> Void)? { get set }
    var didDismissPaymentMethodUI: (() -> Void)? { get set }
    var didCancel: (() -> Void)? { get set }
    func validateReturningPromise() -> Promise<Void>
    func retrieveListOfBanks() -> Promise<[AdyenBank]>
    func filterBanks(query: String) -> [AdyenBank]
    func tokenize(bankId: String) -> Promise<Void>
    func handlePaymentMethodTokenData() -> Promise<Void>
    func cancel()
    func cleanup()
    func subscribeToNotifications()
}
