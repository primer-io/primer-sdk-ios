//
//  PrimerSource.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 25/04/22.
//

import Foundation

@objc public class PrimerSource: NSObject {
    
    public static var defaultSourceType: String = Primer.shared.integrationOptions?.reactNativeVersion == nil ? "IOS_NATIVE" : "RN_IOS"

    private(set) var sourceType: String
    
    public init(sourceType: String) {
        self.sourceType = sourceType
    }
}

extension PrimerSource {
    
    public static var iOSNative: PrimerSource {
        PrimerSource(sourceType: PrimerSource.defaultSourceType)
    }
}
