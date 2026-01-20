//
//  Array.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public extension Array where Element: Equatable {
    func toBatches(of size: UInt) -> [[Element]] {
        stride(from: 0, to: count, by: Int(size)).map {
            Array(self[$0 ..< Swift.min($0 + Int(size), count)])
        }
    }
}

public extension Array where Element == Error {

    var combinedDescription: String {
        var message: String = ""

        self.forEach { err in
            if let primerError = err as? (any PrimerErrorProtocol) {
                message += "\(primerError.localizedDescription) | "
            } else {
                let nsErr = err as NSError
                message += "Domain: \(nsErr.domain), Code: \(nsErr.code), Description: \(nsErr.localizedDescription) | "
            }
        }

        if message.hasSuffix(" | ") {
            message = String(message.dropLast(3))
        }

        return "[\(message)]"
    }
}
