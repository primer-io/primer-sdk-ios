//
//  SessionType.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 13/01/2021.
//

#if canImport(UIKit)

public enum PrimerSessionIntent: String, Codable {
    case checkout = "CHECKOUT"
    case vault = "VAULT"
}

#endif
