//
//  Analytics.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerCore

final class Analytics {
    static let queue: DispatchQueue = DispatchQueue(label: "primer.analytics", qos: .utility)
    static var apiClient: PrimerAPIClientProtocol?
}
