//
//  PrimerUIManager.swift
//  PrimerSDK
//
//  Created by Evangelos on 9/9/22.
//

#if canImport(UIKit)

import UIKit

internal class PrimerUIManager {
    
    internal static var primerWindow: UIWindow?
    internal static var primerRootViewController: PrimerRootViewController?
    
    static func preparePresentation(
        clientToken: String,
        function: String
    ) -> Promise<Void> {
        return Promise { seal in
            var events: [Analytics.Event] = []
            
            let sdkEvent = Analytics.Event(
                eventType: .sdkEvent,
                properties: SDKEventProperties(
                    name: function,
                    params: [
                        "intent": Primer.shared.intent?.rawValue ?? "null"
                    ]))
            
            let connectivityEvent = Analytics.Event(
                eventType: .networkConnectivity,
                properties: NetworkConnectivityEventProperties(
                    networkType: Connectivity.networkType))
            
            
            let timingEvent = Analytics.Event(
                eventType: .timerEvent,
                properties: TimerEventProperties(
                    momentType: .start,
                    id: Primer.shared.timingEventId!))
            
            events = [sdkEvent, connectivityEvent, timingEvent]
            Analytics.Service.record(events: events)
            
            
            firstly {
                PrimerUIManager.prepareRootViewController()
            }
            .then { () -> Promise<Void> in
                return ClientTokenService.storeClientToken(clientToken)
            }
            .then { () -> Promise<Void> in
                let configurationService: PrimerAPIConfigurationServiceProtocol = PrimerAPIConfigurationService(requestDisplayMetadata: true)
                return configurationService.fetchConfigurationAndVaultedPaymentMethods()
            }
            .then { () -> Promise<Void> in
                return PrimerUIManager.validatePaymentUIPresentation()
            }
            .done {
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    static func prepareRootViewController()  -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async {
                if PrimerUIManager.primerRootViewController == nil {
                    PrimerUIManager.primerRootViewController = PrimerRootViewController()
                }
                
                if PrimerUIManager.primerWindow == nil {
                    if #available(iOS 13.0, *) {
                        if let windowScene = UIApplication.shared.connectedScenes.filter({ $0.activationState == .foregroundActive }).first as? UIWindowScene {
                            PrimerUIManager.primerWindow = UIWindow(windowScene: windowScene)
                        } else {
                            // Not opted-in in UISceneDelegate
                            PrimerUIManager.primerWindow = UIWindow(frame: UIScreen.main.bounds)
                        }
                    } else {
                        // Fallback on earlier versions
                        PrimerUIManager.primerWindow = UIWindow(frame: UIScreen.main.bounds)
                    }
                    
                    PrimerUIManager.primerWindow!.rootViewController = PrimerUIManager.primerRootViewController
                    PrimerUIManager.primerWindow!.backgroundColor = UIColor.clear
                    PrimerUIManager.primerWindow!.windowLevel = UIWindow.Level.normal
                    PrimerUIManager.primerWindow!.makeKeyAndVisible()
                }
                
                seal.fulfill()
            }
        }
    }
    
    static func validatePaymentUIPresentation() -> Promise<Void> {
        return Promise { seal in
            if let paymentMethodType = Primer.shared.selectedPaymentMethodType {
                guard let paymentMethod = PrimerPaymentMethod.getPaymentMethod(withType: paymentMethodType) else {
                    let err = PrimerError.unableToPresentPaymentMethod(
                        paymentMethodType: paymentMethodType,
                        userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                        diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                if case .checkout = Primer.shared.intent, paymentMethod.isCheckoutEnabled == false  {
                    let err = PrimerError.unsupportedIntent(
                        intent: .checkout,
                        userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                        diagnosticsId: nil)
                    seal.reject(err)
                    return
                    
                } else if case .vault = Primer.shared.intent, paymentMethod.isVaultingEnabled == false {
                    let err = PrimerError.unsupportedIntent(
                        intent: .vault,
                        userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                        diagnosticsId: nil)
                    seal.reject(err)
                    return
                }
            }
            
            let state: AppStateProtocol = DependencyContainer.resolve()
            
            if Primer.shared.intent == .vault, state.apiConfiguration?.clientSession?.customer?.id == nil {
                let err = PrimerError.invalidValue(key: "customer.id", value: nil, userInfo: [NSLocalizedDescriptionKey: "Make sure you have set a customerId in the client session"], diagnosticsId: nil)
                seal.reject(err)
                return
                
            }
            
            seal.fulfill()
        }
    }
}

#endif
