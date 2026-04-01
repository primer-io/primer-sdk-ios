//
//  WorkflowContainerTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerStepResolver
import XCTest

final class WorkflowContainerTests: XCTestCase {

    func testDecodeContainer() throws {
        let json = #"{"workflowId": "wf-1", "currentStep": {"id": "step-1", "type": "platform.log", "params": {"k": "v"} } }"#
        let container = try JSONDecoder().decode(WorkflowContainer.self, from: Data(json.utf8))
        XCTAssertEqual(container.workflowId, "wf-1")
        XCTAssertEqual(container.currentStep.id, "step-1")
    }

    func testDecodeMissingWorkflowIdThrows() {
        let json = #"{"currentStep": {"id": "step-1", "type": "platform.log", "params": {} } }"#
        XCTAssertThrowsError(try JSONDecoder().decode(WorkflowContainer.self, from: Data(json.utf8)))
    }
}
