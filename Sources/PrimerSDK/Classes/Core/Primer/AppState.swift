//
//  AppState.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 16/01/2021.
//



internal protocol AppStateProtocol: AnyObject {
    
    static var current: AppStateProtocol { get }
    var amount: Int? { get }
    var currency: Currency? { get }
    var clientToken: String? { get set }
    var apiConfiguration: PrimerAPIConfiguration? { get set }
    var paymentMethods: [PrimerPaymentMethodTokenData] { get set }
    var selectedPaymentMethodId: String? { get set }
    var selectedPaymentMethod: PrimerPaymentMethodTokenData? { get }
}

internal class AppState: AppStateProtocol, LogReporter {
    
    static var current: AppStateProtocol {
        let appState: AppStateProtocol = DependencyContainer.resolve()
        return appState
    }
    
    var amount: Int? {
        return PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.merchantAmount ?? PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.totalOrderAmount
    }
    
    var currency: Currency? {
        return PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.currencyCode
    }
    
    var clientToken: String?
    var apiConfiguration: PrimerAPIConfiguration?
    var paymentMethods: [PrimerPaymentMethodTokenData] = []
    var selectedPaymentMethodId: String?
    var selectedPaymentMethod: PrimerPaymentMethodTokenData? {
        guard let selectedPaymentMethodToken = selectedPaymentMethodId else { return nil }
        return paymentMethods.first(where: { $0.id == selectedPaymentMethodToken })
    }

    deinit {
        self.logger.debug(message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
}


