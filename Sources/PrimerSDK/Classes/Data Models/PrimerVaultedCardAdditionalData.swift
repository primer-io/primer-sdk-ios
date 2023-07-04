//
//  PrimerVaultedCardAdditionalData.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 22/6/23.
//

#if canImport(UIKit)

import Foundation

public class PrimerVaultedCardAdditionalData: PrimerVaultedPaymentMethodAdditionalData {
    
    let cvv: String
    
    public init(cvv: String) {
        self.cvv = cvv
    }
}

#endif
