//
//  PrimerTextFieldView+Analytics.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

extension PrimerTextFieldView {

    private func sendTextFieldDidBeginEditingAnalyticsEvent(_ event: Analytics.Event) {
        sendTextFieldDidBeginEditingAnalyticsEventIfNeeded(event)
    }

    private func sendTextFieldDidEndEditingAnalyticsEvent(_ event: Analytics.Event) {
        sendTextFieldDidEndEditingAnalyticsEventIfNeeded(event)
    }
}

extension PrimerTextFieldView {

    internal func sendTextFieldDidBeginEditingAnalyticsEventIfNeeded(_ event: Analytics.Event) {

        guard isEditingAnalyticsEnabled else {
            return
        }

        Analytics.Service.record(event: event)
    }

    internal func sendTextFieldDidEndEditingAnalyticsEventIfNeeded(_ event: Analytics.Event) {

        guard isEditingAnalyticsEnabled else {
            return
        }

        Analytics.Service.record(event: event)
    }
}
