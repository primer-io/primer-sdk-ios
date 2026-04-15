//
//  StateProcessorResponse.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation
import PrimerStepResolver

public struct StateProcessorResponse: Decodable {
    public let newState: CodableState
    public let action: WorkflowStep?
    public let terminal: Terminal?
    public let error: StateProcessorError?
}

public struct Terminal: Decodable {
    public let outcome: TerminalOutcome
}

public struct StateProcessorError: Decodable, LocalizedError {
    public let code: Int
    public let message: String
    public let diagnosticsId: String

    public var errorDescription: String? {
        "State processor error [\(code)] (diagnosticsId=\(diagnosticsId)): \(message)"
    }
}
