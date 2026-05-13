//
//  WorkflowContainer.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal)
public struct WorkflowContainer: Decodable {
    public let currentStep: WorkflowStep
    public let workflowId: String
}
