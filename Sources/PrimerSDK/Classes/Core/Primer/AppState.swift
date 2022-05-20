//
//  AppState.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 16/01/2021.
//

#if canImport(UIKit)

internal protocol AppStateProtocol: AnyObject {
    
    var clientToken: String? { get set }
    var apiConfiguration: PrimerAPIConfiguration? { get set }
    var paymentMethods: [PaymentMethodToken] { get set }
    var selectedPaymentMethodId: String? { get set }
    var selectedPaymentMethod: PaymentMethodToken? { get }
}

internal class AppState: AppStateProtocol {
    
    static var current: AppState {
        let appState: AppStateProtocol = DependencyContainer.resolve()
        return appState as! AppState
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
