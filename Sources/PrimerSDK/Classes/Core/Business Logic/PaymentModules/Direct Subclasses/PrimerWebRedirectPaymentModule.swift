//
//  PrimerWebRedirectPaymentModule.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 29/6/23.
//

import Foundation

internal class PrimerWebRedirectPaymentModule: PrimerPaymentModule {
    
    override func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken) -> Promise<String?> {
        return Promise { seal in
            if decodedJWTToken.intent?.contains("_REDIRECTION") == true {
                if let redirectUrlStr = decodedJWTToken.redirectUrl,
                   let redirectUrl = URL(string: redirectUrlStr),
                   let statusUrlStr = decodedJWTToken.statusUrl,
                   let statusUrl = URL(string: statusUrlStr),
                   decodedJWTToken.intent != nil {
                    
//                    DispatchQueue.main.async {
//                        PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
//                    }
//
//                    self.redirectUrl = redirectUrl
//                    self.statusUrl = statusUrl
                    guard let webRedirectUIModule = self.paymentMethodOrchestrator.uiModule as? PrimerWebRedirectUIModule else {
                        fatalError("\(String(describing: Self.self)) should be initialized with a PrimerWebRedirectUIModule UI module")
                    }
                    
                    webRedirectUIModule.redirectUrl = redirectUrl
                    
                    guard let webRedirectDataInputModule = self.paymentMethodOrchestrator.dataInputModule as? PrimerWebRedirectInputDataModule else {
                        fatalError("\(String(describing: Self.self)) should be initialized with a PrimerWebRedirectDataInputModule data input module")
                    }
                    
                    webRedirectDataInputModule.statusUrl = statusUrl
                    
                    firstly {
                        self.paymentMethodOrchestrator.uiModule.presentPaymentUI()
                    }
                    .then { () -> Promise<PrimerInputDataProtocol> in
                        return self.paymentMethodOrchestrator.dataInputModule.awaitUserInput()
                    }
                    .done { resumeTokenContainer in
                        self.paymentMethodOrchestrator.uiModule.dismissPaymentUI()
                        seal.fulfill((resumeTokenContainer as! ResumeTokenContainer).resumeToken)
                    }
                    .catch { err in
                        seal.reject(err)
                    }
                } else {
                    let err = PrimerError.invalidClientToken(
                        userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                        diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                }
            } else {
                seal.fulfill(nil)
            }
        }
    }
}
