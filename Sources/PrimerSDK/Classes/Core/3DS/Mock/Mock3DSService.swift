//
//  Test3DSService.swift
//  Pods-Debug App
//
//  Created by Niall Quinn on 08/09/23.
//

import Foundation
import UIKit

class Mock3DSService: ThreeDSServiceProtocol {
    static var apiClient: PrimerAPIClientProtocol?
    private var demo3DSWindow: UIWindow?
    
    func perform3DS(
        paymentMethodTokenData: PrimerPaymentMethodTokenData,
        sdkDismissed: (() -> Void)?,
        completion: @escaping (_ result: Result<String, Error>) -> Void) {
            if #available(iOS 13.0, *) {
                if let windowScene = UIApplication.shared.connectedScenes.filter({ $0.activationState == .foregroundActive }).first as? UIWindowScene {
                    demo3DSWindow = UIWindow(windowScene: windowScene)
                } else {
                    // Not opted-in in UISceneDelegate
                    demo3DSWindow = UIWindow(frame: UIScreen.main.bounds)
                }
            } else {
                // Fallback on earlier versions
                demo3DSWindow = UIWindow(frame: UIScreen.main.bounds)
            }
            
            demo3DSWindow!.rootViewController = ClearViewController()
            demo3DSWindow!.backgroundColor = UIColor.clear
            demo3DSWindow!.windowLevel = UIWindow.Level.alert
            demo3DSWindow!.makeKeyAndVisible()
            
            let vc = PrimerDemo3DSViewController()
            demo3DSWindow!.rootViewController?.present(vc, animated: true)
            
            vc.onSendCredentialsButtonTapped = {
                self.demo3DSWindow?.rootViewController = nil
                self.demo3DSWindow = nil
                completion(.success(paymentMethodTokenData.token ?? "no-token"))
            }
        }
}
