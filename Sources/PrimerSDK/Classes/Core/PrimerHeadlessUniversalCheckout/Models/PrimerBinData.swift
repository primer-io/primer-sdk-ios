//
//  PrimerBinData.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@objc
public enum PrimerBinDataStatus: Int {
    case partial
    case complete
}

@objc
public final class PrimerBinData: NSObject {
    public let preferred: PrimerCardNetwork?
    public let alternatives: [PrimerCardNetwork]
    public let status: PrimerBinDataStatus
    public let firstDigits: String?
    let fallbackDigits: String?

    init(preferred: PrimerCardNetwork?,
         alternatives: [PrimerCardNetwork],
         status: PrimerBinDataStatus,
         firstDigits: String?,
         fallbackDigits: String? = nil) {
        self.preferred = preferred
        self.alternatives = alternatives
        self.status = status
        self.firstDigits = firstDigits
        self.fallbackDigits = fallbackDigits
    }

    override public var description: String {
        """
        PrimerBinData(\
        preferred: \(preferred?.displayName ?? "nil"), \
        alternatives: [\(alternatives.map(\.displayName).joined(separator: ", "))], \
        status: \(status == .complete ? "complete" : "partial"), \
        firstDigits: \(firstDigits ?? "nil"))
        """
    }
}
