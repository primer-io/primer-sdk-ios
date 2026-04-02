//
//  BDCEngineProtocol.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerBDCEngine
import PrimerFoundation

@MainActor
protocol BDCEngineProtocol {
    func start(schema: String, context: SDKContext, state: CodableValue) async throws -> AnyDict
    func applyResult(schema: String, actionId: String, state: CodableState, outcome: String, data: Data?) async throws -> AnyDict
    func applyEvent(_ event: CodableValue, schema: String, state: CodableState) async throws -> AnyDict
}

extension PrimerBDCEngine: BDCEngineProtocol {}
