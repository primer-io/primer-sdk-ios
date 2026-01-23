//
//  PrimerThreeDsOptions.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

public struct PrimerThreeDsOptions: Codable {
    public let threeDsAppRequestorUrl: String?

    public init(threeDsAppRequestorUrl: String? = nil) {
        self.threeDsAppRequestorUrl = threeDsAppRequestorUrl
    }
}
