//
//  PrimerSource.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 25/04/22.
//



import Foundation

class PrimerSource {
    
    static var defaultSourceType: String = Primer.shared.integrationOptions?.reactNativeVersion == nil ? "IOS_NATIVE" : "RN_IOS"

    private(set) var sourceType: String
    
    init(sourceType: String) {
        self.sourceType = sourceType
    }
}

extension PrimerSource {
    
    static var sdkSourceType: PrimerSource {
        PrimerSource(sourceType: PrimerSource.defaultSourceType)
    }
}


