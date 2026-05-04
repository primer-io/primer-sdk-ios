//
//  DemoProtocol.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

@available(iOS 15.0, *)
struct DemoConfiguration {
    let settings: PrimerSettings
    let apiVersion: PrimerApiVersion
    let clientSession: ClientSessionRequestBody?
    let clientToken: String?
}

struct DemoMetadata: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let tags: [String]
    let isCustom: Bool
}

@available(iOS 15.0, *)
protocol CheckoutComponentsDemo: View {
    static var metadata: DemoMetadata { get }
    init(configuration: DemoConfiguration)
}
