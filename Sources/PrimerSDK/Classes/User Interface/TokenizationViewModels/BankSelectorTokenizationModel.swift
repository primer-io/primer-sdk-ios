//
//  BankSelectorTokenizationModel.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 16.11.2023.
//

import Foundation
protocol BankSelectorTokenizationDelegate {
    var paymentMethodType: PrimerPaymentMethodType { get set }
    func validateReturningPromise() -> Promise<Void>
    func retrieveListOfBanks() -> Promise<[AdyenBank]>
    func filterBanks(query: String) -> [AdyenBank]
    func tokenize(bankId: String) -> Promise<Void>
    func cancel()
}
