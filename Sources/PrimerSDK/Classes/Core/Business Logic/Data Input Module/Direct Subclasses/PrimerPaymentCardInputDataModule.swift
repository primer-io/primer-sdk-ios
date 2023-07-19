//
//  PrimerPaymentCardDataInputModule.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 30/6/23.
//

#if canImport(UIKit)

import Foundation

class PrimerPaymentCardInputDataModule: PrimerInputDataModule {
    
    override func awaitUserInput() -> Promise<PrimerInputDataProtocol> {
        return Promise { seal in
            self.onInputDataSet = { inputData in
                seal.fulfill(inputData)
            }
        }
    }
}

#endif
