//
//  Logger.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import os

final class Logger {
	static func handleJSLog(_ message: String) {
        info(message, category: category(from: message))
	}
    
    static func handleJSErr(_ message: String) {
        guard #available(iOS 14.0, *) else { return print(message) }
        let logger = os.Logger(subsystem: "BDCStateProcessor", category: category(from: message))
        logger.error("\(message)")
    }
    
    static func info(_ message: String, category: String ) {
        guard #available(iOS 14.0, *) else { return print(message) }
        let logger = os.Logger(subsystem: "BDCStateProcessor", category: category)
        logger.info("\(message)")
    }

	private static func category(from message: String) -> String {
		LogEvent.allCases.first { message.contains($0.rawValue) }?.rawValue ?? "UNKNOWN"
	}
}

private enum LogEvent: String, CaseIterable {
	case applyEvent = "APPLY_EVENT"
	case evaluateExpression = "EVALUATE_EXPRESSION"
	case processUITree = "PROCESS_UI_TREE"
	case applyWorkflowStepResponse = "APPLY_WORKFLOW_STEP_RESPONSE"
	case evaluateTriggers = "EVALUATE_TRIGGERS"
	case evaluateTriggersAndGetWorkflows = "EVALUATE_TRIGGERS_AND_GET_WORKFLOWS"
	case resolveNextWorkflowStep = "RESOLVE_NEXT_WORKFLOW_STEP"
}
