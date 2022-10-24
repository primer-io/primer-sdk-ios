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
    internal static var apiConfigurationModule: PrimerAPIConfigurationModuleProtocol?
    
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
                        "intent": PrimerInternal.shared.intent?.rawValue ?? "null"
                    ]))
            
            let connectivityEvent = Analytics.Event(
                eventType: .networkConnectivity,
                properties: NetworkConnectivityEventProperties(
                    networkType: Connectivity.networkType))
            
            
            let timingEvent = Analytics.Event(
                eventType: .timerEvent,
                properties: TimerEventProperties(
                    momentType: .start,
                    id: PrimerInternal.shared.timingEventId!))
            
            events = [sdkEvent, connectivityEvent, timingEvent]
            Analytics.Service.record(events: events)
                        
            firstly {
                PrimerUIManager.prepareRootViewController()
            }
            .then { () -> Promise<Void> in
                let isHeadlessCheckoutDelegateImplemented = PrimerHeadlessUniversalCheckout.current.delegate != nil
                let apiConfigurationModule = PrimerUIManager.apiConfigurationModule ?? PrimerAPIConfigurationModule()
                
                return apiConfigurationModule.setupSession(
                    forClientToken: clientToken,
                    requestDisplayMetadata: true,
                    requestClientTokenValidation: false,
                    requestVaultedPaymentMethods: !isHeadlessCheckoutDelegateImplemented)
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
        if let paymentMethodType = PrimerInternal.shared.selectedPaymentMethodType {
            PrimerUIManager.presentPaymentMethod(type: paymentMethodType)
        } else if PrimerInternal.shared.intent == .checkout {
            let pucvc = PrimerUniversalCheckoutViewController()
            PrimerUIManager.primerRootViewController?.show(viewController: pucvc)
        } else if PrimerInternal.shared.intent == .vault {
            let pvmvc = PrimerVaultManagerViewController()
            PrimerUIManager.primerRootViewController?.show(viewController: pvmvc)
        } else {
            let err = PrimerError.invalidValue(key: "paymentMethodType", value: nil, userInfo: [NSLocalizedDescriptionKey: "Make sure you have set a payment method type"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            PrimerUIManager.handleErrorBasedOnSDKSettings(err)
        }
    }
    
    static func presentPaymentMethod(type: String) {
        let paymentMethodTokenizationViewModel = PrimerAPIConfigurationModule.paymentMethodModules.filter({ $0.paymentMethodConfiguration.type == type }).first
        
        precondition(paymentMethodTokenizationViewModel != nil, "PrimerUIManager should have validated that the view model exists.")
        
        var imgView: UIImageView?
        if let squareLogo = PrimerAPIConfigurationModule.paymentMethodModules.filter({ $0.paymentMethodConfiguration.type == type }).first?.userInterfaceModule.icon {
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
        
        paymentMethodTokenizationViewModel?.checkouEventsNotifierModule.willPresentPaymentMethodUI = {
            PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: imgView, message: nil)
        }
        
        paymentMethodTokenizationViewModel?.checkouEventsNotifierModule.didPresentPaymentMethodUI = {}
        
        paymentMethodTokenizationViewModel?.checkouEventsNotifierModule.willDismissPaymentMethodUI = {
            PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: imgView, message: nil)
        }
        
        paymentMethodTokenizationViewModel?.startFlow()
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
            if let paymentMethodType = PrimerInternal.shared.selectedPaymentMethodType {
                guard let paymentMethod = PrimerPaymentMethod.getPaymentMethod(withType: paymentMethodType) else {
                    let err = PrimerError.unableToPresentPaymentMethod(
                        paymentMethodType: paymentMethodType,
                        userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                        diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                guard PrimerAPIConfigurationModule.paymentMethodModules.first(where: { $0.paymentMethodConfiguration.type == paymentMethodType }) != nil else {
                    let err = PrimerError.unableToPresentPaymentMethod(
                        paymentMethodType: paymentMethodType,
                        userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                        diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                if case .checkout = PrimerInternal.shared.intent, paymentMethod.isCheckoutEnabled == false  {
                    let err = PrimerError.unsupportedIntent(
                        intent: .checkout,
                        userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                        diagnosticsId: nil)
                    seal.reject(err)
                    return
                    
                } else if case .vault = PrimerInternal.shared.intent, paymentMethod.isVaultingEnabled == false {
                    let err = PrimerError.unsupportedIntent(
                        intent: .vault,
                        userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                        diagnosticsId: nil)
                    seal.reject(err)
                    return
                }
            }
            
            let state: AppStateProtocol = DependencyContainer.resolve()
            
            if PrimerInternal.shared.intent == .vault, state.apiConfiguration?.clientSession?.customer?.id == nil {
                let err = PrimerError.invalidValue(key: "customer.id", value: nil, userInfo: [NSLocalizedDescriptionKey: "Make sure you have set a customerId in the client session"], diagnosticsId: nil)
                seal.reject(err)
                return
                
            }
            
            seal.fulfill()
        }
    }
    
    static func dismissPrimerUI(animated flag: Bool, completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            guard let primerRootViewController = PrimerUIManager.primerRootViewController else {
                completion?()
                return
            }
            
            primerRootViewController.dismissPrimerRootViewController(animated: flag) {
                DispatchQueue.main.async {
                    PrimerUIManager.primerWindow?.isHidden = true
                    if #available(iOS 13, *) {
                        PrimerUIManager.primerWindow?.windowScene = nil
                    }
                    PrimerUIManager.primerWindow?.rootViewController = nil
                    PrimerUIManager.primerRootViewController = nil
                    PrimerUIManager.primerWindow?.resignKey()
                    PrimerUIManager.primerWindow = nil
                    completion?()
                }
            }
        }
    }
    
    static func dismissOrShowResultScreen(type: PrimerResultViewController.ScreenType, withMessage message: String? = nil) {
        if PrimerSettings.current.uiOptions.isSuccessScreenEnabled && type == .success {
            showResultScreenForResultType(type: .success, message: message)
        } else if PrimerSettings.current.uiOptions.isErrorScreenEnabled && type == .failure {
            showResultScreenForResultType(type: .failure, message: message)
        } else {
            PrimerInternal.shared.dismiss()
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
