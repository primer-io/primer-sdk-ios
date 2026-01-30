//
//  PrimerTextFieldView+Analytics.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerCore
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

    func sendTextFieldDidBeginEditingAnalyticsEventIfNeeded(_ event: Analytics.Event) {

        guard isEditingAnalyticsEnabled else {
            return
        }

        Analytics.Service.fire(event: event)
    }

    func sendTextFieldDidEndEditingAnalyticsEventIfNeeded(_ event: Analytics.Event) {

        guard isEditingAnalyticsEnabled else {
            return
        }

        Analytics.Service.fire(event: event)
    }
}
