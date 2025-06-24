//
//  PrimerUIManager.swift
//  PrimerSDK
//
//  Created by Evangelos on 9/9/22.
//

// swiftlint:disable function_body_length

import UIKit
import SwiftUI

/// Defines the checkout presentation style for the Primer SDK.
public enum CheckoutStyle {
    /// Traditional UIKit-based Drop-in checkout system
    case dropIn
    /// Modern SwiftUI-based CheckoutComponents system (iOS 15+ required)
    case composable
    /// Automatically choose based on iOS version and availability
    case automatic
}

protocol PrimerUIManaging {
    var primerWindow: UIWindow? { get }
    var primerRootViewController: PrimerRootViewController? { get }
    var apiConfigurationModule: PrimerAPIConfigurationModuleProtocol? { get }

    func prepareRootViewController() -> Promise<Void>
    func dismissOrShowResultScreen(type: PrimerResultViewController.ScreenType,
                                   paymentMethodManagerCategories: [PrimerPaymentMethodManagerCategory],
                                   withMessage message: String?)
}

final class PrimerUIManager: PrimerUIManaging {

    static let shared: PrimerUIManager = .init()

    static var primerWindow: UIWindow? {
        shared.primerWindow
    }
    static var primerRootViewController: PrimerRootViewController? {
        shared.primerRootViewController
    }
    static var apiConfigurationModule: PrimerAPIConfigurationModuleProtocol? {
        shared.apiConfigurationModule
    }

    var primerWindow: UIWindow?
    var primerRootViewController: PrimerRootViewController?
    var apiConfigurationModule: PrimerAPIConfigurationModuleProtocol?

    func preparePresentation(clientToken: String) -> Promise<Void> {
        return Promise { seal in
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

    func presentPaymentUI() {
        presentPaymentUI(checkoutStyle: .composable)
    }

    func presentPaymentUI(checkoutStyle: CheckoutStyle) {
        if let paymentMethodType = PrimerInternal.shared.selectedPaymentMethodType {
            PrimerUIManager.presentPaymentMethod(type: paymentMethodType)
        } else if PrimerInternal.shared.intent == .checkout {
            let resolvedStyle = resolveCheckoutStyle(checkoutStyle)

            switch resolvedStyle {
            case .composable:
                if #available(iOS 15.0, *) {
                    presentComposableCheckout()
                } else {
                    // Fallback to Drop-in if iOS 15+ not available
                    presentDropInCheckout()
                }
            case .dropIn:
                presentDropInCheckout()
            case .automatic:
                // This case should not occur as resolveCheckoutStyle handles it
                presentDropInCheckout()
            }
        } else if PrimerInternal.shared.intent == .vault {
            let pvmvc = PrimerVaultManagerViewController()
            PrimerUIManager.primerRootViewController?.show(viewController: pvmvc)
        } else {
            let err = PrimerError.invalidValue(key: "paymentMethodType",
                                               value: nil,
                                               userInfo: [NSLocalizedDescriptionKey: "Make sure you have set a payment method type"],
                                               diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            PrimerUIManager.handleErrorBasedOnSDKSettings(err)
        }
    }

    private func resolveCheckoutStyle(_ style: CheckoutStyle) -> CheckoutStyle {
        switch style {
        case .automatic:
            // Choose CheckoutComponents for iOS 15+, otherwise Drop-in
            if #available(iOS 15.0, *) {
                return .composable
            } else {
                return .dropIn
            }
        case .composable, .dropIn:
            return style
        }
    }

    private func presentDropInCheckout() {
        let pucvc = PrimerUniversalCheckoutViewController()
        PrimerUIManager.primerRootViewController?.show(viewController: pucvc)
    }

    @available(iOS 15.0, *)
    private func presentComposableCheckout() {
        // Get client token from the current app state
        let state: AppStateProtocol = DependencyContainer.resolve()
        guard let clientToken = state.clientToken else {
            let error = PrimerError.invalidClientToken(
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: error)
            PrimerUIManager.handleErrorBasedOnSDKSettings(error)
            return
        }

        // Set PrimerUIManager as the delegate to handle success/failure results
        CheckoutComponentsPrimer.shared.delegate = self
        
        // CheckoutComponentsPrimer now handles traditional UI integration internally
        // It will initialize PrimerRootViewController and present through the traditional system
        CheckoutComponentsPrimer.presentCheckout(with: clientToken) {
            // Presentation completed through traditional UI system
        }
    }
    
    @available(iOS 15.0, *)
    private func handleSwiftUIHeightChange(_ height: CGFloat) {
        // This can be used for additional height change handling if needed
        // The bridge controller already updates preferredContentSize automatically
    }

    @available(iOS 15.0, *)
    func handleSwiftUIHeightChange(_ newHeight: CGFloat, for hostController: UIViewController) {
        guard let root = PrimerUIManager.primerRootViewController,
              // Find the matching container for this host
              let container = root.navController
                .viewControllers
                .compactMap({ $0 as? PrimerContainerViewController })
                .first(where: { $0.childViewController === hostController })
        else { return }

        // Compute total sheet height (content + nav bar)
        let navBarHeight = root.navController.navigationBar.bounds.height
        let total = newHeight + navBarHeight

        // Update the constraint and animate
        container.childViewHeightConstraint?.constant = total
        UIView.animate(withDuration: 0.3) {
            root.view.layoutIfNeeded()
        }
    }

    func presentPaymentMethod(type: String) {
        let paymentMethodTokenizationViewModel = PrimerAPIConfiguration.paymentMethodConfigViewModels.filter({ $0.config.type == type }).first

        guard let paymentMethodTokenizationViewModel else {
            let error = PrimerError.unableToPresentPaymentMethod(
                paymentMethodType: type,
                userInfo: .errorUserInfoDictionary(
                    additionalInfo: ["message": "paymentMethodTokenizationViewModel was not present when calling presentPaymentMethod"]
                ),
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: error)
            return
        }

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

        paymentMethodTokenizationViewModel.checkoutEventsNotifierModule.didStartTokenization = {
            PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: imgView, message: nil)
        }

        paymentMethodTokenizationViewModel.willPresentPaymentMethodUI = {
            PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: imgView, message: nil)
        }

        paymentMethodTokenizationViewModel.didPresentPaymentMethodUI = {}

        paymentMethodTokenizationViewModel.willDismissPaymentMethodUI = {
            PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: imgView, message: nil)
        }

        paymentMethodTokenizationViewModel.start()
    }

    func prepareRootViewController() -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async {
                if PrimerUIManager.primerRootViewController == nil {
                    self.primerRootViewController = PrimerRootViewController()
                }

                if PrimerUIManager.primerWindow == nil {
                    if let windowScene = UIApplication.shared.connectedScenes
                        .filter({ $0.activationState == .foregroundActive })
                        .first as? UIWindowScene {
                        self.primerWindow = UIWindow(windowScene: windowScene)
                    } else {
                        // Not opted-in in UISceneDelegate
                        self.primerWindow = UIWindow(frame: UIScreen.main.bounds)
                    }

                    self.primerWindow!.rootViewController = self.primerRootViewController
                    self.primerWindow!.backgroundColor = UIColor.clear
                    self.primerWindow!.windowLevel = UIWindow.Level.normal
                    self.primerWindow!.makeKeyAndVisible()
                }

                seal.fulfill()
            }
        }
    }

    func validatePaymentUIPresentation() -> Promise<Void> {
        return Promise { seal in
            if let paymentMethodType = PrimerInternal.shared.selectedPaymentMethodType {
                guard let paymentMethod = PrimerPaymentMethod.getPaymentMethod(withType: paymentMethodType) else {
                    let err = PrimerError.unableToPresentPaymentMethod(
                        paymentMethodType: paymentMethodType,
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }

                guard PrimerAPIConfiguration.paymentMethodConfigViewModels.first(where: { $0.config.type == paymentMethodType }) != nil else {
                    let err = PrimerError.unableToPresentPaymentMethod(
                        paymentMethodType: paymentMethodType,
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }

                if case .checkout = PrimerInternal.shared.intent, paymentMethod.isCheckoutEnabled == false {
                    let err = PrimerError.unsupportedIntent(
                        intent: .checkout,
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString)
                    seal.reject(err)
                    return

                } else if case .vault = PrimerInternal.shared.intent, paymentMethod.isVaultingEnabled == false {
                    let err = PrimerError.unsupportedIntent(
                        intent: .vault,
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString)
                    seal.reject(err)
                    return
                }
            }

            let state: AppStateProtocol = DependencyContainer.resolve()

            if PrimerInternal.shared.intent == .vault, state.apiConfiguration?.clientSession?.customer?.id == nil {
                let err = PrimerError.invalidValue(key: "customer.id",
                                                   value: nil,
                                                   userInfo: [NSLocalizedDescriptionKey: "Make sure you have set a customerId in the client session"],
                                                   diagnosticsId: UUID().uuidString)
                seal.reject(err)
                return

            }

            seal.fulfill()
        }
    }

    @discardableResult
    func dismissPrimerUI(animated flag: Bool) -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async {
                self.dismissPrimerUI(animated: flag) {
                    seal.fulfill()
                }
            }
        }
    }

    func dismissPrimerUI(animated flag: Bool, completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            guard let primerRootViewController = self.primerRootViewController else {
                self.dismissPrimerWindow(completion: completion)
                completion?()
                return
            }

            if #available(iOS 16.1, *) {
                primerRootViewController.dismissPrimerRootViewController(animated: flag) {
                    self.dismissPrimerWindow(completion: completion)
                }
            } else if #available(iOS 16.0, *) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    primerRootViewController.dismissPrimerRootViewController(animated: flag) {
                        self.dismissPrimerWindow(completion: completion)
                    }
                }
            } else {
                primerRootViewController.dismissPrimerRootViewController(animated: flag) {
                    self.dismissPrimerWindow(completion: completion)
                }
            }
        }
    }

    func dismissPrimerWindow(completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            self.primerWindow?.isHidden = true
            self.primerWindow?.windowScene = nil
            self.primerWindow?.resignKey()
            self.primerWindow = nil
            self.primerRootViewController = nil
            completion?()
        }
    }

    func dismissOrShowResultScreen(type: PrimerResultViewController.ScreenType,
                                   paymentMethodManagerCategories: [PrimerPaymentMethodManagerCategory],
                                   withMessage message: String? = nil) {
        if PrimerSettings.current.uiOptions.isSuccessScreenEnabled && type == .success {
            showResultScreenForResultType(type: .success, message: message)
        } else if PrimerSettings.current.uiOptions.isErrorScreenEnabled && type == .failure {
            showResultScreenForResultType(type: .failure, message: message)
        } else {
            PrimerInternal.shared.dismiss(
                paymentMethodManagerCategories: paymentMethodManagerCategories
            )
        }
    }

    func handleErrorBasedOnSDKSettings(_ error: PrimerError) {
        PrimerDelegateProxy.primerDidFailWithError(error, data: nil) { errorDecision in
            switch errorDecision.type {
            case .fail(let message):
                PrimerUIManager.dismissOrShowResultScreen(type: .failure,
                                                          paymentMethodManagerCategories: [],
                                                          withMessage: message)
            }
        }
    }

    fileprivate func showResultScreen(for paymentMethodType: PrimerPaymentMethodType, error: PrimerError?) {
        let resultViewController = PrimerCustomResultViewController(paymentMethodType: paymentMethodType, error: error)
        PrimerUIManager.primerRootViewController?.show(viewController: resultViewController)
    }

    fileprivate func showResultScreenForResultType(type: PrimerResultViewController.ScreenType, message: String? = nil) {
        let resultViewController = PrimerResultViewController(screenType: type, message: message)
        resultViewController.view.translatesAutoresizingMaskIntoConstraints = false
        resultViewController.view.heightAnchor.constraint(equalToConstant: 300).isActive = true
        PrimerUIManager.primerRootViewController?.show(viewController: resultViewController)
    }
}

// Legacy static support
extension PrimerUIManager {

    static func preparePresentation(clientToken: String) -> Promise<Void> {
        shared.preparePresentation(clientToken: clientToken)
    }

    static func presentPaymentUI() {
        shared.presentPaymentUI()
    }

    static func presentPaymentMethod(type: String) {
        shared.presentPaymentMethod(type: type)
    }

    static func prepareRootViewController() -> Promise<Void> {
        shared.prepareRootViewController()
    }

    static func validatePaymentUIPresentation() -> Promise<Void> {
        shared.validatePaymentUIPresentation()
    }

    @discardableResult
    static func dismissPrimerUI(animated flag: Bool) -> Promise<Void> {
        shared.dismissPrimerUI(animated: flag)
    }

    static func dismissPrimerUI(animated flag: Bool, completion: (() -> Void)? = nil) {
        shared.dismissPrimerUI(animated: flag, completion: completion)
    }

    static func dismissPrimerWindow(completion: (() -> Void)? = nil) {
        shared.dismissPrimerWindow(completion: completion)
    }

    static func dismissOrShowResultScreen(type: PrimerResultViewController.ScreenType,
                                          paymentMethodManagerCategories: [PrimerPaymentMethodManagerCategory],
                                          withMessage message: String? = nil) {
        shared.dismissOrShowResultScreen(type: type, paymentMethodManagerCategories: paymentMethodManagerCategories, withMessage: message)
    }

    static func handleErrorBasedOnSDKSettings(_ error: PrimerError) {
        shared.handleErrorBasedOnSDKSettings(error)
    }

    static func showResultScreen(for paymentMethodType: PrimerPaymentMethodType, error: PrimerError?) {
        shared.showResultScreen(for: paymentMethodType, error: error)
    }

    static fileprivate func showResultScreenForResultType(type: PrimerResultViewController.ScreenType,
                                                          message: String? = nil) {
        shared.showResultScreenForResultType(type: type, message: message)
    }
}
// swiftlint:enable function_body_length

// MARK: - CheckoutComponentsDelegate Implementation

@available(iOS 15.0, *)
extension PrimerUIManager: CheckoutComponentsDelegate {
    
    func checkoutComponentsDidCompleteWithSuccess() {
        // CheckoutComponents is now integrated with traditional UI system
        // Result screens are handled automatically through traditional dismissOrShowResultScreen
        dismissOrShowResultScreen(
            type: .success,
            paymentMethodManagerCategories: [],
            withMessage: "Payment successful"
        )
    }
    
    func checkoutComponentsDidFailWithError(_ error: PrimerError) {
        // CheckoutComponents is now integrated with traditional UI system
        // Result screens are handled automatically through traditional dismissOrShowResultScreen
        dismissOrShowResultScreen(
            type: .failure,
            paymentMethodManagerCategories: [],
            withMessage: error.localizedDescription
        )
    }
    
    func checkoutComponentsDidDismiss() {
        // Handle dismissal - this is called when checkout is dismissed without completion
        // Use the existing dismissal mechanism
        PrimerInternal.shared.dismiss(paymentMethodManagerCategories: [])
    }
}
