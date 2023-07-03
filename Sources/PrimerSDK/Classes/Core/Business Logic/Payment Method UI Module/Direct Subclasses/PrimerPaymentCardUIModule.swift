//
//  PrimerPaymentCardUIModule.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 3/7/23.
//

#if canImport(UIKit)

import Foundation

class PrimerPaymentCardUIModule: PrimerPaymentMethodUIModule {
    
    override func presentPreTokenizationUI() -> Promise<Void> {
        return Promise { seal in
            // Present card form
        }
    }
    
    override func presentPaymentUI() -> Promise<Void> {
        return Promise { seal in
            // Present 3DS (native or processor)
        }
    }
}

#endif
