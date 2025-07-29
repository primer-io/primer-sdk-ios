//
//  Notification.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

internal extension Notification.Name {

    static let receivedUrlSchemeRedirect        = Notification.Name(rawValue: "PrimerURLSchemeRedirect")
    static let receivedUrlSchemeCancellation    = Notification.Name(rawValue: "PrimerURLSchemeCancellation")
}
