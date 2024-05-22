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
