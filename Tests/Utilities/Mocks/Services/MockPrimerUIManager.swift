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

    var onPrepareViewController: (() -> Promise<Void>)?

    func prepareRootViewController() -> PrimerSDK.Promise<Void> {
        return onPrepareViewController?() ?? Promise { $0.resolve(.success(()))}
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
