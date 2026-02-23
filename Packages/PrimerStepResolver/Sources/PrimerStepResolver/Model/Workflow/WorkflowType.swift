//
//  WorkflowType.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation

public enum WorkflowType {
    case analytics(CodableValue)
    case httpCall(CodableValue)
    case urlOpen(params: CodableValue, eventContainer: EventContainer)
    case uiRender
}
