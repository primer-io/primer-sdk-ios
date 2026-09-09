//
//  ComponentsCheckoutModule.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
@_spi(PrimerInternal)
public struct ComponentsCheckoutModule {

    public let type: String
    public let options: [String: Bool]?

    public init(type: String, options: [String: Bool]?) {
        self.type = type
        self.options = options
    }
}
