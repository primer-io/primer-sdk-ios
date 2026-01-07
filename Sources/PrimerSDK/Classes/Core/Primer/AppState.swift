//
//  AppState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

//
//  AppState.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.
import PrimerFoundation

protocol AppStateProtocol: AnyObject {

    static var current: AppStateProtocol { get }
    var amount: Int? { get }
    var currency: Currency? { get }
    var clientToken: String? { get set }
    var apiConfiguration: PrimerAPIConfiguration? { get set }
    var paymentMethods: [PrimerPaymentMethodTokenData] { get set }
    var selectedPaymentMethodId: String? { get set }
    var selectedPaymentMethod: PrimerPaymentMethodTokenData? { get }
}

final class AppState: AppStateProtocol {

    static var current: AppStateProtocol {
        let appState: AppStateProtocol = DependencyContainer.resolve()
        return appState
    }

    var amount: Int? {
        PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.merchantAmount ??
            PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.totalOrderAmount
    }

    var currency: Currency? {
        PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.currencyCode
    }

    var clientToken: String?
    var apiConfiguration: PrimerAPIConfiguration?
    var paymentMethods: [PrimerPaymentMethodTokenData] = []
    var selectedPaymentMethodId: String?
    var selectedPaymentMethod: PrimerPaymentMethodTokenData? {
        guard let selectedPaymentMethodToken = selectedPaymentMethodId else { return nil }
        return paymentMethods.first(where: { $0.id == selectedPaymentMethodToken })
    }
}
