//
//  BankSelectorTokenizationModel.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 16.11.2023.
//

import Foundation

protocol TokenizationDelegate {
    func setup()
    func cleanup()
    func cancel()
}

protocol BankSelectorTokenizationDelegate: TokenizationDelegate {
    var paymentMethodType: PrimerPaymentMethodType { get set }
    func validateReturningPromise() -> Promise<Void>
    func retrieveListOfBanks() -> Promise<[AdyenBank]>
    func filterBanks(query: String) -> [AdyenBank]
    func tokenize(bankId: String) -> Promise<Void>

}

protocol WebRedirectTokenizationDelegate: TokenizationDelegate {
    var didFinishPayment: ((Error?) -> Void)? { get set }
    var didPresentPaymentMethodUI: (() -> Void)? { get set }
    var didDismissPaymentMethodUI: (() -> Void)? { get set }
    var didCancel: (() -> Void)? { get set }
    func handlePaymentMethodTokenData() -> Promise<Void>
}
