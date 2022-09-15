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
    
    static func presentPaymentUI() {
        if let paymentMethodType = Primer.shared.selectedPaymentMethodType {
            PrimerUIManager.presentPaymentMethod(type: paymentMethodType)
        } else if Primer.shared.intent == .checkout {
            let pucvc = PrimerUniversalCheckoutViewController()
            PrimerUIManager.primerRootViewController?.show(viewController: pucvc)
        } else if Primer.shared.intent == .vault {
            let pvmvc = PrimerVaultManagerViewController()
            PrimerUIManager.primerRootViewController?.show(viewController: pvmvc)
        } else {
            let err = PrimerError.invalidValue(key: "paymentMethodType", value: nil, userInfo: [NSLocalizedDescriptionKey: "Make sure you have set a payment method type"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            PrimerUIManager.handleErrorBasedOnSDKSettings(err)
        }
    }
    
    static func presentPaymentMethod(type: String) {
        let paymentMethodTokenizationViewModel = PrimerAPIConfiguration.paymentMethodConfigViewModels.filter({ $0.config.type == type }).first
        
        precondition(paymentMethodTokenizationViewModel != nil, "PrimerUIManager should have validated that the view model exists.")
        
        var imgView: UIImageView?
        if let squareLogo = PrimerAPIConfiguration.paymentMethodConfigViewModels.filter({ $0.config.type == type }).first?.uiModule.icon {
            imgView = UIImageView()
            imgView?.image = squareLogo
            imgView?.contentMode = .scaleAspectFit
            imgView?.translatesAutoresizingMaskIntoConstraints = false
            imgView?.heightAnchor.constraint(equalToConstant: 24.0).isActive = true
            imgView?.widthAnchor.constraint(equalToConstant: 24.0).isActive = true
        }
        
        PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: imgView, message: nil)
        
        paymentMethodTokenizationViewModel?.checkouEventsNotifierModule.didStartTokenization = {
            PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: imgView, message: nil)
        }
        
        paymentMethodTokenizationViewModel?.willPresentPaymentMethodUI = {
            PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: imgView, message: nil)
        }
        
        paymentMethodTokenizationViewModel?.didPresentPaymentMethodUI = {}
        
        paymentMethodTokenizationViewModel?.willDismissPaymentMethodUI = {
            PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: imgView, message: nil)
        }
        
        paymentMethodTokenizationViewModel?.start()
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
                
                guard PrimerAPIConfiguration.paymentMethodConfigViewModels.first(where: { $0.config.type == paymentMethodType }) != nil else {
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
    
    static func dismissOrShowResultScreen(type: PrimerResultViewController.ScreenType, withMessage message: String? = nil) {
        if PrimerSettings.current.uiOptions.isSuccessScreenEnabled && type == .success {
            showResultScreenForResultType(type: .success, message: message)
        } else if PrimerSettings.current.uiOptions.isErrorScreenEnabled && type == .failure {
            showResultScreenForResultType(type: .failure, message: message)
        } else {
            Primer.shared.dismiss()
        }
    }
    
    static func handleErrorBasedOnSDKSettings(_ error: PrimerError) {
        PrimerDelegateProxy.primerDidFailWithError(error, data: nil) { errorDecision in
            switch errorDecision.type {
            case .fail(let message):
                PrimerUIManager.dismissOrShowResultScreen(type: .failure, withMessage: message)
            }
        }
    }
    
    static private func showResultScreenForResultType(type: PrimerResultViewController.ScreenType, message: String? = nil) {
        let resultViewController = PrimerResultViewController(screenType: type, message: message)
        resultViewController.view.translatesAutoresizingMaskIntoConstraints = false
        resultViewController.view.heightAnchor.constraint(equalToConstant: 300).isActive = true
        PrimerUIManager.primerRootViewController?.show(viewController: resultViewController)
    }
}

#endif
