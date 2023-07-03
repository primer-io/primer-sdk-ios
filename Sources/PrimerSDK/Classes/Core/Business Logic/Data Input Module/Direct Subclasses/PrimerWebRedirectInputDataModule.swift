//
//  PrimerWebRedirectDataInputModule.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 30/6/23.
//

#if canImport(UIKit)

import Foundation

struct ResumeTokenContainer: PrimerInputDataProtocol {
    var resumeToken: String
}

class PrimerWebRedirectInputDataModule: PrimerInputDataModule {
    
    var statusUrl: URL!
    
    override func awaitUserInput() -> Promise<PrimerInputDataProtocol> {
        return Promise { seal in
            let pollingModule = PollingModule(url: self.statusUrl)
            
            firstly { () -> Promise<String> in
//                if self.isCancelled {
//                    let err = PrimerError.cancelled(paymentMethodType: self.config.type, userInfo: nil, diagnosticsId: UUID().uuidString)
//                    throw err
//                }
                return pollingModule.start()
            }
            .done { resumeToken in
                let resumeTokenContainer = ResumeTokenContainer(resumeToken: resumeToken)
                seal.fulfill(resumeTokenContainer)
            }
            .ensure {
//                self.didCancel = nil
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
}

#endif
