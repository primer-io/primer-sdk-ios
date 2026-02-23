//
//  WorkflowStep.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

public struct WorkflowStep: Decodable {
    public let type: WorkflowType
    public let stepId: String
    
    private enum StepCodingKeys: String, CodingKey {
        case events
        case params
        case properties
        case schema
        case stepId
        case type
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: StepCodingKeys.self)
        stepId = try container.decode(String.self, forKey: .stepId)
        let params = try container.decode(CodableValue.self, forKey: .params)
    
        switch try container.decode(StepDomain.self, forKey: .type) {
        case .analyticsLog: type = .analytics(params)
        case .httpRequest: type = .httpCall(params)
        case .urlOpen: type = .urlOpen(params: params, eventContainer: try container.decode(EventContainer.self, forKey: .events))
        case .uiRender: type = .uiRender
        }
    }
}
