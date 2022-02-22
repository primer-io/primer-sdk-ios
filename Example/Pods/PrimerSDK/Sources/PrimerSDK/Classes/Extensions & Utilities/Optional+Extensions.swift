//
//  Optional+Extensions.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 07/03/2021.
//

#if canImport(UIKit)

internal extension Optional {
    var exists: Bool { return self != nil }
}

#endif
