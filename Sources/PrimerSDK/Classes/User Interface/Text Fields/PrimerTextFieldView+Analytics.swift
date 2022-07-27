//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
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
