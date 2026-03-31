//
//  ClientSessionAction.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

public struct ClientSessionAction: Encodable {
    public let actions: [ClientSession.Action]

    public init(actions: [ClientSession.Action]) {
        self.actions = actions
    }
}

public struct ClientSessionUpdateRequest: Encodable {
    public let actions: ClientSessionAction

    public init(actions: ClientSessionAction) {
        self.actions = actions
    }
}
