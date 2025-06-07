//
//  File.swift
//
//
//  Created by Jack Newcombe on 22/05/2024.
//

import UIKit
@testable import PrimerSDK

class MockPrimerUIManager: PrimerUIManaging {

    // MARK: Properties

    var primerWindow: UIWindow?

    var primerRootViewController: PrimerSDK.PrimerRootViewController?
    var apiConfigurationModule: (any PrimerSDK.PrimerAPIConfigurationModuleProtocol)?

    // MARK: prepareRootViewController

    var onPrepareViewController: (() -> Void)?

    func prepareRootViewController() -> PrimerSDK.Promise<Void> {
        onPrepareViewController?()
        return Promise.fulfilled(())
    }

    func prepareRootViewController() async throws {
        onPrepareViewController?()
    }

    // MARK: dismissOrShowResultScreen

    var onDismissOrShowResultScreen: ((PrimerResultViewController.ScreenType,
                                       [PrimerPaymentMethodManagerCategory],
                                       String?) -> Void)?

    func dismissOrShowResultScreen(type: PrimerResultViewController.ScreenType, paymentMethodManagerCategories: [PrimerPaymentMethodManagerCategory], withMessage message: String?) {
        onDismissOrShowResultScreen?(type, paymentMethodManagerCategories, message)
    }
}

class MockPrimerRootViewController: PrimerRootViewController {

    // MARK: show

    var onShow: ((UIViewController, Bool) -> Void)?

    var latestViewController: UIViewController?

    override func show(viewController: UIViewController, animated: Bool = false) {
        latestViewController = viewController
        onShow?(viewController, animated)
    }

    // MARK: present

    var onPresent: ((UIViewController, Bool) -> Void)?

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        latestViewController = viewControllerToPresent
        onPresent?(viewControllerToPresent, flag)
        completion?()
    }

    // MARK: showLoadingScreenIfNeeded

    override func showLoadingScreenIfNeeded(imageView: UIImageView?, message: String?) {
    }

    // MARK: enableUserInteraction

    override func enableUserInteraction(_ isUserInteractionEnabled: Bool) {
    }
}
