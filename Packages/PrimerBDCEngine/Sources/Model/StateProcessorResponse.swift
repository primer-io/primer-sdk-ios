//
//  StateProcessorResponse.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import PrimerStepResolver

// processing result
public struct StateProcessorResponse: Decodable {
    public let newState: CodableState
    public let nextToExecute: WorkflowStep?
    public let terminal: Terminal?
}

public struct Terminal: Decodable {
    let outcome: TerminalOutcome
}

public enum TerminalOutcome: String, Decodable {
    case success
    case cancelled
    case error
}
