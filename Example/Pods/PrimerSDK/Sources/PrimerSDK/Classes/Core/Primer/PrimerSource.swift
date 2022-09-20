//
//  PrimerSource.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 25/04/22.
//

import Foundation

@objc public class PrimerSource: NSObject {
    
    public static var defaultSourceType: String = "IOS_NATIVE"

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
