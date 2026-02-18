//
//  StateProcessorResponse.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import PrimerStepResolver

public struct StateProcessorResponse: Decodable {
    public let newState: CodableState
    public let workflowsToRun: [WorkflowContainer]
}
