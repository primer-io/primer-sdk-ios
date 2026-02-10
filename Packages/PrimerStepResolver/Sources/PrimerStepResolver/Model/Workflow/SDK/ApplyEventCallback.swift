//
//  ApplyEventCallback.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation

public struct ApplyEventCallback {
    public let event: Event
    public let screenId: String
    public let state: CodableState
    
    public init(event: Event, screenId: String, state: CodableState) {
        self.event = event
        self.screenId = screenId
        self.state = state
    }
}
