//
//  PrimerApiVersion.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

public enum PrimerApiVersion: String, Codable {
    case V2_4 = "2.4"

    public static let latest = PrimerApiVersion.V2_4
}
