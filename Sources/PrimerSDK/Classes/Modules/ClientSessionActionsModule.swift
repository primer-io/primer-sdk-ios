//
//  ClientSessionActionsModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 11/7/22.
//

#if canImport(UIKit)

import Foundation

protocol ClientSessionActionsProtocol {
    
    init(apiClient: PrimerAPIClientProtocol)
    func selectPaymentMethodIfNeeded(_ paymentMethodType: String, cardNetwork: String?) -> Promise<Void>
    func unselectPaymentMethodIfNeeded() -> Promise<Void>
    func dispatch(actions: [ClientSession.Action]) -> Promise<Void>
}

class ClientSessionActionsModule: ClientSessionActionsProtocol {
    
    private let apiClient: PrimerAPIClientProtocol
    
    required init(apiClient: PrimerAPIClientProtocol = PrimerAPIClient()) {
        self.apiClient = apiClient
    }
    
    func selectPaymentMethodIfNeeded(_ paymentMethodType: String, cardNetwork: String?) -> Promise<Void> {
        return Promise { seal in
            guard PrimerInternal.shared.intent == .checkout else {
                seal.fulfill()
                return
            }
            
            if (PrimerAPIConfigurationModule.apiConfiguration?.hasSurchargeEnabled ?? false) == false {
                seal.fulfill()
                return
            }
            
            var params: [String: Any] = ["paymentMethodType": paymentMethodType]
            
            if let cardNetwork = cardNetwork {
                params["binData"] = [
                    "network": cardNetwork
                ]
            }
            let actions = [ClientSession.Action.selectPaymentMethodActionWithParameters(params)]
            let clientSessionActionsRequest = ClientSessionUpdateRequest(actions: ClientSessionAction(actions: actions))
            
            PrimerDelegateProxy.primerClientSessionWillUpdate()
            
            let apiConfigurationModule = PrimerAPIConfigurationModule(apiClient: self.apiClient)
            firstly {
                apiConfigurationModule.updateSession(withActions: clientSessionActionsRequest)
            }
            .done {
                if PrimerAPIConfigurationModule.apiConfiguration != nil {
                    PrimerDelegateProxy.primerClientSessionDidUpdate(PrimerClientSession(from: PrimerAPIConfigurationModule.apiConfiguration!))
                }
               
                seal.fulfill()
            }
            .catch { error in
                seal.reject(error)
            }
        }
    }
    
    func unselectPaymentMethodIfNeeded() -> Promise<Void> {
        return Promise { seal in
            guard PrimerInternal.shared.intent == .checkout else {
                seal.fulfill()
                return
            }
            
            if (PrimerAPIConfigurationModule.apiConfiguration?.hasSurchargeEnabled ?? false) == false {
                seal.fulfill()
                return
            }
            
            let unselectPaymentMethodAction = ClientSession.Action(type: .unselectPaymentMethod, params: nil)
            let clientSessionActionsRequest = ClientSessionUpdateRequest(actions: ClientSessionAction(actions: [unselectPaymentMethodAction]))
            
            PrimerDelegateProxy.primerClientSessionWillUpdate()
            let apiConfigurationModule = PrimerAPIConfigurationModule(apiClient: self.apiClient)
            
            firstly {
                apiConfigurationModule.updateSession(withActions: clientSessionActionsRequest)
            }
            .done {
                if PrimerAPIConfigurationModule.apiConfiguration != nil {
                    PrimerDelegateProxy.primerClientSessionDidUpdate(PrimerClientSession(from: PrimerAPIConfigurationModule.apiConfiguration!))
                }
                
                seal.fulfill()
            }
            .catch { error in
                seal.reject(error)
            }
        }
    }
    
    func dispatch(actions: [ClientSession.Action]) -> Promise<Void> {
        return Promise { seal in
            let clientSessionActionsRequest = ClientSessionUpdateRequest(actions: ClientSessionAction(actions: actions))
            
            PrimerDelegateProxy.primerClientSessionWillUpdate()
            let apiConfigurationModule = PrimerAPIConfigurationModule(apiClient: self.apiClient)
            
            firstly {
                apiConfigurationModule.updateSession(withActions: clientSessionActionsRequest)
            }
            .done {
                if AppState.current.apiConfiguration != nil {
                    PrimerDelegateProxy.primerClientSessionDidUpdate(PrimerClientSession(from: PrimerAPIConfigurationModule.apiConfiguration!))
                }
                
                seal.fulfill()
            }
            .catch { error in
                seal.reject(error)
            }
        }
    }
}

#endif
