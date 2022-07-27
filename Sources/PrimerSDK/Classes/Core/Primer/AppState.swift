//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

#if canImport(UIKit)

internal protocol AppStateProtocol: AnyObject {
    static var current: AppStateProtocol { get }
    var amount: Int? { get }
    var currency: Currency? { get }
    var clientToken: String? { get set }
    var apiConfiguration: PrimerAPIConfiguration? { get set }
    var paymentMethods: [PaymentMethodToken] { get set }
    var selectedPaymentMethodId: String? { get set }
    var selectedPaymentMethod: PaymentMethodToken? { get }
}

internal class AppState: AppStateProtocol {
    
    static var current: AppStateProtocol {
        let appState: AppStateProtocol = DependencyContainer.resolve()
        return appState
    }
    
    var amount: Int? {
        return AppState.current.apiConfiguration?.clientSession?.order?.merchantAmount ?? AppState.current.apiConfiguration?.clientSession?.order?.totalOrderAmount
    }
    
    var currency: Currency? {
        return AppState.current.apiConfiguration?.clientSession?.order?.currencyCode
    }
    
    var clientToken: String?
    var apiConfiguration: PrimerAPIConfiguration?
    var paymentMethods: [PaymentMethodToken] = []
    var selectedPaymentMethodId: String?
    var selectedPaymentMethod: PaymentMethodToken? {
        guard let selectedPaymentMethodToken = selectedPaymentMethodId else { return nil }
        return paymentMethods.first(where: { $0.id == selectedPaymentMethodToken })
    }

    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
}

#endif
