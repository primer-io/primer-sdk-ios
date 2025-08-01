//
//  Mock3DSService.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import UIKit

final class Mock3DSService: ThreeDSServiceProtocol {
    static var apiClient: PrimerAPIClientProtocol?
    private var demo3DSWindow: UIWindow?

    func perform3DS(
        paymentMethodTokenData: PrimerPaymentMethodTokenData,
        sdkDismissed: (() -> Void)?,
        completion: @escaping (_ result: Result<String, Error>) -> Void) {

        if let windowScene = UIApplication.shared.connectedScenes.filter({ $0.activationState == .foregroundActive }).first as? UIWindowScene {
            demo3DSWindow = UIWindow(windowScene: windowScene)
        } else {
            // Not opted-in in UISceneDelegate
            demo3DSWindow = UIWindow(frame: UIScreen.main.bounds)
        }

        demo3DSWindow!.rootViewController = ClearViewController()
        demo3DSWindow!.backgroundColor = UIColor.clear
        demo3DSWindow!.windowLevel = UIWindow.Level.alert
        demo3DSWindow!.makeKeyAndVisible()

        let viewController = PrimerDemo3DSViewController()
        demo3DSWindow!.rootViewController?.present(viewController, animated: true)

        viewController.onSendCredentialsButtonTapped = {
            self.demo3DSWindow?.rootViewController = nil
            self.demo3DSWindow = nil
            completion(.success(paymentMethodTokenData.token ?? "no-token"))
        }
    }

    func perform3DS(
        paymentMethodTokenData: PrimerPaymentMethodTokenData,
        sdkDismissed: (() -> Void)?
    ) async throws -> String {
        try await awaitResult { completion in
            perform3DS(
                paymentMethodTokenData: paymentMethodTokenData,
                sdkDismissed: sdkDismissed,
                completion: completion
            )
        }
    }

}
