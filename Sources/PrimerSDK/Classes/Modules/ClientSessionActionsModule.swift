//
//  ClientSessionActionsModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 11/7/22.
//

#if canImport(UIKit)

import Foundation

protocol ClientSessionActionsProtocol {
    
    func selectPaymentMethodIfNeeded(_ paymentMethodType: String, cardNetwork: String?) -> Promise<Void>
    func unselectPaymentMethodIfNeeded() -> Promise<Void>
    func dispatch(actions: [ClientSession.Action]) -> Promise<Void>
}

class ClientSessionActionsModule: ClientSessionActionsProtocol {
    
    func selectPaymentMethodIfNeeded(_ paymentMethodType: String, cardNetwork: String?) -> Promise<Void> {
        return Promise { seal in
            guard PrimerInternal.shared.intent == .checkout else {
                seal.fulfill()
                return
            }
            
            if PrimerAPIConfigurationModule.apiConfiguration?.hasSurchargeEnabled == false {
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
            
            firstly {
                PrimerAPIConfigurationModule.updateSession(withActions: clientSessionActionsRequest)
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
            
            if PrimerAPIConfigurationModule.apiConfiguration?.hasSurchargeEnabled == false {
                seal.fulfill()
                return
            }
            
            let unselectPaymentMethodAction = ClientSession.Action(type: .unselectPaymentMethod, params: nil)
            let clientSessionActionsRequest = ClientSessionUpdateRequest(actions: ClientSessionAction(actions: [unselectPaymentMethodAction]))
            
            PrimerDelegateProxy.primerClientSessionWillUpdate()
            
            firstly {
                PrimerAPIConfigurationModule.updateSession(withActions: clientSessionActionsRequest)
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
            
            firstly {
                PrimerAPIConfigurationModule.updateSession(withActions: clientSessionActionsRequest)
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
