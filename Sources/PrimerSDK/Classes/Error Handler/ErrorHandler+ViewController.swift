//
//  ErrorHandler+ViewController.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 21/03/22.
//

#if canImport(UIKit)

import UIKit

final class DismissOrShowingResultScreenErrorHandler: ErrorHandlerProtocol {
    
    func handle(error: Error?) {
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

        if settings.hasDisabledSuccessScreen {
            Primer.shared.dismiss()
        } else {
            let status: PrimerResultViewController.ScreenType = error == nil ? .success : .failure
            let resultViewController = PrimerResultViewController(screenType: status, message: error?.localizedDescription)
            resultViewController.view.translatesAutoresizingMaskIntoConstraints = false
            resultViewController.view.heightAnchor.constraint(equalToConstant: 300).isActive = true
            Primer.shared.primerRootVC?.show(viewController: resultViewController)
        }
    }
}

extension DismissOrShowingResultScreenErrorHandler {
    
    func handleSuccessOnly() {
        self.handle(error: nil)
    }
}

#endif
