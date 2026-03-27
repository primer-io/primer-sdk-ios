//
//  TerminalOutcome.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

public enum TerminalOutcome: String, Decodable {
    case success
    case cancelled
    case error
}
