//
//  WorkflowStep.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

public struct WorkflowStep: Decodable {
    public let id: String
    public let type: String
    public let params: CodableValue
}
