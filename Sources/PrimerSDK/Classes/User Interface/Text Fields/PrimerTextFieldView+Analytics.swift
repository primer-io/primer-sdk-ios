//
//  PrimerTextFieldView+Analytics.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 07/06/22.
//

#if canImport(UIKit)

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

#endif
