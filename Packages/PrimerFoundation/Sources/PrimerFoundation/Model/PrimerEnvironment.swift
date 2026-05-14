//
//  PrimerEnvironment.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal)
public enum PrimerEnvironment: String, Codable {
    case dev = "DEV"
    case staging = "STAGING"
    case sandbox = "SANDBOX"
    case production = "PRODUCTION"
}
