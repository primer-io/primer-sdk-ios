//
//  BDCEngineProtocol.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

@MainActor
public protocol BDCEngineProtocol: AnyObject {
    func start(schema: String, context: SDKContext, state: CodableValue) async throws -> AnyDict
    func applyResult(schema: String, context: SDKContext, actionId: String, state: CodableState, outcome: String, data: Data?) async throws -> AnyDict
}
