//
//  DatadogErrorClassifier.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
enum DatadogErrorClassifier {

    static func shouldReport(_ error: Error) -> Bool {
        (error as? PrimerErrorProtocol)?.isReportable ?? true
    }
}

// MARK: - Error Extension

@available(iOS 15.0, *)
extension Error {
    var shouldReportToDatadog: Bool {
        DatadogErrorClassifier.shouldReport(self)
    }
}
