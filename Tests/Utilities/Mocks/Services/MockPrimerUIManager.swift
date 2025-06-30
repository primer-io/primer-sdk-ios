//
//  MockPrimerUIManager.swift
//
//
//  Created by Jack Newcombe on 22/05/2024.
//

import UIKit
@testable import PrimerSDK

final class MockPrimerUIManager: PrimerUIManaging {

    // MARK: Properties

    var primerWindow: UIWindow?
    var primerRootViewController: PrimerRootViewController?
    var apiConfigurationModule: (any PrimerSDK.PrimerAPIConfigurationModuleProtocol)?

    var onPrepareViewController: (() -> Result<Void, Error>)?
    var onDismissOrShowResultScreen: ((PrimerResultViewController.ScreenType, [PrimerPaymentMethodManagerCategory], String?) -> Void)?

    func prepareRootViewController() -> Promise<Void> {
        switch onPrepareViewController?() {
        case .success(let success): .fulfilled(success)
        case .failure(let failure): .rejected(failure)
        case nil: .rejected(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
        }
    }

    func prepareRootViewController() async throws {
        switch onPrepareViewController?() {
        case .success(let success): return success
        case .failure(let failure): throw failure
        case nil: throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }
    }

    // MARK: dismissOrShowResultScreen

    func dismissOrShowResultScreen(
        type: PrimerResultViewController.ScreenType,
        paymentMethodManagerCategories: [PrimerPaymentMethodManagerCategory],
        withMessage message: String?
    ) {
        onDismissOrShowResultScreen?(type, paymentMethodManagerCategories, message)
    }
}

final class MockPrimerRootViewController: PrimerRootViewController {

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
