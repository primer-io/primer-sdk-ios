//
//  PrimerUIManager.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable function_body_length
// swiftlint:disable type_body_length
// swiftlint:disable file_length

import UIKit

protocol PrimerUIManaging {
    var primerWindow: UIWindow? { get }
    var primerRootViewController: PrimerRootViewController? { get }
    var apiConfigurationModule: PrimerAPIConfigurationModuleProtocol? { get }
    @MainActor func prepareRootViewController()
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

    func preparePresentation(clientToken: String) async throws {
        await PrimerUIManager.prepareRootViewController()
        let isHeadlessCheckoutDelegateImplemented = PrimerHeadlessUniversalCheckout.current.delegate != nil
        let apiConfigurationModule = PrimerUIManager.apiConfigurationModule ?? PrimerAPIConfigurationModule()

        try await apiConfigurationModule.setupSession(
            forClientToken: clientToken,
            requestDisplayMetadata: true,
            requestClientTokenValidation: false,
            requestVaultedPaymentMethods: !isHeadlessCheckoutDelegateImplemented
        )

        try PrimerUIManager.validatePaymentUIPresentation()
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
            let err = PrimerError.invalidValue(key: "paymentMethodType")
            ErrorHandler.handle(error: err)
            PrimerUIManager.handleErrorBasedOnSDKSettings(err)
        }
    }

    func presentPaymentMethod(type: String) {
        let paymentMethodTokenizationViewModel = PrimerAPIConfiguration.paymentMethodConfigViewModels.filter({ $0.config.type == type }).first

        guard let paymentMethodTokenizationViewModel else {
            let error = PrimerError.unableToPresentPaymentMethod(
                paymentMethodType: type,
                reason: "Payment method is not available for this session. Only present payment methods that are included in availablePaymentMethods"
            )
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

    @MainActor
    func prepareRootViewController() {
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

    func validatePaymentUIPresentation() throws {
        if let paymentMethodType = PrimerInternal.shared.selectedPaymentMethodType {
            guard let paymentMethod = PrimerPaymentMethod.getPaymentMethod(withType: paymentMethodType) else {
                let reason = "Payment method type is not recognized by the SDK"
                throw handled(primerError: .unableToPresentPaymentMethod(paymentMethodType: paymentMethodType, reason: reason))
            }

            guard PrimerAPIConfiguration.paymentMethodConfigViewModels.first(where: { $0.config.type == paymentMethodType }) != nil else {
                let reason = "Payment method is not in availablePaymentMethods. Only show payment methods returned by start() or listAvailablePaymentMethodsForCheckout()"
                throw handled(primerError: .unableToPresentPaymentMethod(paymentMethodType: paymentMethodType, reason: reason))
            }

            if case .checkout = PrimerInternal.shared.intent, paymentMethod.isCheckoutEnabled == false {
                throw handled(primerError: .unsupportedIntent(intent: .checkout))

            } else if case .vault = PrimerInternal.shared.intent, paymentMethod.isVaultingEnabled == false {
                throw handled(primerError: .unsupportedIntent(intent: .vault))
            }
        }

        let state: AppStateProtocol = DependencyContainer.resolve()

        if PrimerInternal.shared.intent == .vault, state.apiConfiguration?.clientSession?.customer?.id == nil {
            throw handled(primerError: .invalidValue(key: "customer.id"))
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
        if PrimerSettings.current.uiOptions.isSuccessScreenEnabled, type == .success {
            showResultScreenForResultType(type: .success, message: message)
        } else if PrimerSettings.current.uiOptions.isErrorScreenEnabled, type == .failure {
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
            case let .fail(message):
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

    static func preparePresentation(clientToken: String) async throws {
        try await shared.preparePresentation(clientToken: clientToken)
    }

    @MainActor
    static func presentPaymentUI() {
        shared.presentPaymentUI()
    }

    static func presentPaymentMethod(type: String) {
        shared.presentPaymentMethod(type: type)
    }

    @MainActor
    static func prepareRootViewController() {
        shared.prepareRootViewController()
    }

    static func validatePaymentUIPresentation() throws {
        try shared.validatePaymentUIPresentation()
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

    fileprivate static func showResultScreenForResultType(type: PrimerResultViewController.ScreenType,
                                                          message: String? = nil) {
        shared.showResultScreenForResultType(type: type, message: message)
    }
}
// swiftlint:enable function_body_length
// swiftlint:enable type_body_length
// swiftlint:enable file_length
