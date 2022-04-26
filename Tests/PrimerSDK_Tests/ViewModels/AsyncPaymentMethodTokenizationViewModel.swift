//
//  AsyncPaymentMethodTokenizationViewModel.swift
//  PrimerSDK_Tests
//
//  Created by Dario Carlomagno on 26/04/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import XCTest
import SafariServices
@testable import PrimerSDK

class MockAsyncPaymentMethodTokenizationViewModel: ExternalPaymentMethodTokenizationViewModel {
    
    var failValidation: Bool = false {
        didSet {
            let state: AppStateProtocol = DependencyContainer.resolve()
            state.clientToken = nil
        }
    }
    var returnedPaymentMethodJson: String?
    
    fileprivate func tokenize() -> Promise<PaymentMethodToken> {
        return Promise { seal in
            guard let _ = config.id else {
                let err = PrimerError.invalidValue(key: "configuration.\(config.type.rawValue.lowercased()).id", value: config.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            if let returnedPaymentMethodJson = returnedPaymentMethodJson,
               let returnedPaymentMethodData = returnedPaymentMethodJson.data(using: .utf8),
               let paymentMethod = try? JSONDecoder().decode(PaymentMethodToken.self, from: returnedPaymentMethodData) {
                seal.fulfill(paymentMethod)
            } else {
                let err = ParserError.failedToDecode(message: "Failed to decode tokenization response.", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                seal.reject(err)
            }
        }
    }
    
    internal override func presentAsyncPaymentMethod(with url: URL) -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async { [unowned self] in
                self.webViewController = SFSafariViewController(url: url)
                self.webViewController?.delegate = self
                self.willPresentExternalView?()
                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                    self.didPresentExternalView?()
                    seal.fulfill(())
                }
            }
        }
    }
    
    internal func startPolling(on url: URL, completion: @escaping (_ id: String?, _ err: Error?) -> Void) {
        //        {
        //          "status" : "COMPLETE",
        //          "id" : "4474848f-721d-4c35-9325-e287196f7016",
        //          "source" : "WEBHOOK",
        //          "urls" : {
        //            "status" : "https:\/\/api.staging.primer.io\/resume-tokens\/4474848f-721d-4c35-9325-e287196f7016",
        //            "redirect" : "https:\/\/api.staging.primer.io\/resume-tokens\/4474848f-721d-4c35-9325-e287196f7016\/complete?api_key=9e66ba99-e154-4e34-9d96-91777859b85b",
        //            "complete" : "https:\/\/api.staging.primer.io\/resume-tokens\/4474848f-721d-4c35-9325-e287196f7016\/complete"
        //          }
        //        }
        completion("4474848f-721d-4c35-9325-e287196f7016", nil)
    }
    
}
