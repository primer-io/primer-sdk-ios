//
//  PrimerSource.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

final class PrimerSource {

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
