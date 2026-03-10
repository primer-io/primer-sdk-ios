//
//  ClientSessionAPIModel.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation
import PrimerNetworking

public struct ClientSessionAction: Encodable {
    let actions: [ClientSession.Action]
}

public struct ClientSessionUpdateRequest: Encodable {
    let actions: ClientSessionAction
}
