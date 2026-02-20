//
//  WorkflowStep.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

public struct WorkflowStep: Decodable {
    public let type: WorkflowType
    
    private enum StepCodingKeys: String, CodingKey {
        case params
        case properties
        case schema
        case stepId
        case type
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: StepCodingKeys.self)
        let params = try container.decode(CodableValue.self, forKey: .params)
    
        switch try container.decode(StepDomain.self, forKey: .type) {
        case .platformLog: type = .log(params: params)
        case .httpRequest: type = .httpCall(params: params)
        case .urlOpen: type = .urlOpen(params: params)
        }
    }
}
