//
//  PrimerUIManager.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable function_body_length
// swiftlint:disable type_body_length
// swiftlint:disable file_length

import UIKit

protocol PrimerUIManaging {
    var primerWindow: UIWindow? { get }
    var primerRootViewController: PrimerRootViewController? { get }
    var apiConfigurationModule: PrimerAPIConfigurationModuleProtocol? { get }

    func prepareRootViewController() -> Promise<Void>
    @MainActor
    func prepareRootViewController_main_actor()
    func dismissOrShowResultScreen(type: PrimerResultViewController.ScreenType,
                                   paymentMethodManagerCategories: [PrimerPaymentMethodManagerCategory],
                                   withMessage message: String?)
}

// MARK: MISSING_TESTS
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

    func preparePresentation(clientToken: String) async throws {
        await PrimerUIManager.prepareRootViewController_main_actor()
        let isHeadlessCheckoutDelegateImplemented = PrimerHeadlessUniversalCheckout.current.delegate != nil
        let apiConfigurationModule = PrimerUIManager.apiConfigurationModule ?? PrimerAPIConfigurationModule()

        try await apiConfigurationModule.setupSession(
            forClientToken: clientToken,
            requestDisplayMetadata: true,
            requestClientTokenValidation: false,
            requestVaultedPaymentMethods: !isHeadlessCheckoutDelegateImplemented
        )

        try PrimerUIManager.validatePaymentUIPresentation_throws()
    }

    func presentPaymentUI() {
        if let paymentMethodType = PrimerInternal.shared.selectedPaymentMethodType {
            PrimerUIManager.presentPaymentMethod(type: paymentMethodType)
        } else if PrimerInternal.shared.intent == .checkout {
            let pucvc = PrimerUniversalCheckoutViewController()
            PrimerUIManager.primerRootViewController?.show(viewController: pucvc)
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

    @MainActor
    func prepareRootViewController_main_actor() {
        if PrimerUIManager.primerRootViewController == nil {
            primerRootViewController = PrimerRootViewController()
        }

        if PrimerUIManager.primerWindow == nil {
            if let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                primerWindow = UIWindow(windowScene: windowScene)
            } else {
                // Not opted-in in UISceneDelegate
                primerWindow = UIWindow(frame: UIScreen.main.bounds)
            }

            primerWindow!.rootViewController = primerRootViewController
            primerWindow!.backgroundColor = UIColor.clear
            primerWindow!.windowLevel = UIWindow.Level.normal
            primerWindow!.makeKeyAndVisible()
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

    func validatePaymentUIPresentation_throws() throws {
        if let paymentMethodType = PrimerInternal.shared.selectedPaymentMethodType {
            guard let paymentMethod = PrimerPaymentMethod.getPaymentMethod(withType: paymentMethodType) else {
                throw handled(primerError: .unableToPresentPaymentMethod(paymentMethodType: paymentMethodType))
            }

            guard PrimerAPIConfiguration.paymentMethodConfigViewModels.first(where: { $0.config.type == paymentMethodType }) != nil else {
                throw handled(primerError: .unableToPresentPaymentMethod(paymentMethodType: paymentMethodType))
            }

            if case .checkout = PrimerInternal.shared.intent, paymentMethod.isCheckoutEnabled == false {
                throw handled(primerError: .unsupportedIntent(intent: .checkout))

            } else if case .vault = PrimerInternal.shared.intent, paymentMethod.isVaultingEnabled == false {
                throw handled(primerError: .unsupportedIntent(intent: .vault))
            }
        }

        let state: AppStateProtocol = DependencyContainer.resolve()

        if PrimerInternal.shared.intent == .vault, state.apiConfiguration?.clientSession?.customer?.id == nil {
            throw handled(primerError: .invalidValue(key: "customer.id",
                                                     userInfo: [NSLocalizedDescriptionKey: "Make sure you have set a customerId in the client session"]))
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

    @MainActor
    func dismissPrimerUI_async(animated flag: Bool) async {
        await withCheckedContinuation { continuation in
            self.dismissPrimerUI(animated: flag) {
                continuation.resume()
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

    static func preparePresentation(clientToken: String) async throws {
        try await shared.preparePresentation(clientToken: clientToken)
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

    @MainActor
    static func prepareRootViewController_main_actor() {
        shared.prepareRootViewController_main_actor()
    }

    static func validatePaymentUIPresentation() -> Promise<Void> {
        shared.validatePaymentUIPresentation()
    }

    static func validatePaymentUIPresentation_throws() throws {
        try shared.validatePaymentUIPresentation_throws()
    }

    @discardableResult
    static func dismissPrimerUI(animated flag: Bool) -> Promise<Void> {
        shared.dismissPrimerUI(animated: flag)
    }

    @MainActor
    static func dismissPrimerUI_async(animated flag: Bool) async {
        await shared.dismissPrimerUI_async(animated: flag)
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
// swiftlint:enable type_body_length
// swiftlint:enable file_length
