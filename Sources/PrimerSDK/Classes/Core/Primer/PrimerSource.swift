//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
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
