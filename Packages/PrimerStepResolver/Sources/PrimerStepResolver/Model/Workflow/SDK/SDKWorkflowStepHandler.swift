//
//  SDKWorkflowStepHandler.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

public protocol SDKWorkflowStepHandler: ObservableObject, StepResolver {
    var callback: ((SDKWorkflowCallback) async throws -> Void)? { get set }
    var updateUITree: ((AnyDict) -> Void)? { get }
    var state: CodableState { get set }
    var initialScreenID: String? { get set }
}
