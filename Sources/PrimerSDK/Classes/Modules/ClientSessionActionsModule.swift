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
            
            if AppState.current.apiConfiguration?.hasSurchargeEnabled == false {
                seal.fulfill()
                return
            }
            
            if AppState.current.apiConfiguration?.hasSurchargeEnabled == false {
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
            
            let clientSessionService: ClientSessionServiceProtocol = ClientSessionService()
            let clientSessionActionsRequest = ClientSessionUpdateRequest(actions: ClientSessionAction(actions: actions))
            
            PrimerDelegateProxy.primerClientSessionWillUpdate()
            
            firstly {
                clientSessionService.requestPrimerConfigurationWithActions(actionsRequest: clientSessionActionsRequest)
            }
            .done { primerApiConfiguration in
                AppState.current.apiConfiguration?.clientSession = primerApiConfiguration.clientSession
                
                if AppState.current.apiConfiguration != nil {
                    PrimerDelegateProxy.primerClientSessionDidUpdate(PrimerClientSession(from: AppState.current.apiConfiguration!))
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
            
            if AppState.current.apiConfiguration?.hasSurchargeEnabled == false {
                seal.fulfill()
                return
            }
            
            if AppState.current.apiConfiguration?.hasSurchargeEnabled == false {
                seal.fulfill()
                return
            }
            
            let unselectPaymentMethodAction = ClientSession.Action(type: .unselectPaymentMethod, params: nil)
            let clientSessionService: ClientSessionServiceProtocol = ClientSessionService()
            let clientSessionActionsRequest = ClientSessionUpdateRequest(actions: ClientSessionAction(actions: [unselectPaymentMethodAction]))
            
            PrimerDelegateProxy.primerClientSessionWillUpdate()
            
            firstly {
                clientSessionService.requestPrimerConfigurationWithActions(actionsRequest: clientSessionActionsRequest)
            }
            .done { primerApiConfiguration in
                AppState.current.apiConfiguration?.clientSession = primerApiConfiguration.clientSession
                
                if AppState.current.apiConfiguration != nil {
                    PrimerDelegateProxy.primerClientSessionDidUpdate(PrimerClientSession(from: AppState.current.apiConfiguration!))
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
            let clientSessionService: ClientSessionServiceProtocol = ClientSessionService()
            let clientSessionActionsRequest = ClientSessionUpdateRequest(actions: ClientSessionAction(actions: actions))
            
            PrimerDelegateProxy.primerClientSessionWillUpdate()
            
            firstly {
                clientSessionService.requestPrimerConfigurationWithActions(actionsRequest: clientSessionActionsRequest)
            }
            .done { primerApiConfiguration in
                AppState.current.apiConfiguration?.clientSession = primerApiConfiguration.clientSession
                
                if AppState.current.apiConfiguration != nil {
                    PrimerDelegateProxy.primerClientSessionDidUpdate(PrimerClientSession(from: AppState.current.apiConfiguration!))
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
