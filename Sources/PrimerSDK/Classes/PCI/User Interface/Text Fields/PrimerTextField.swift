//
//  PrimerTextField.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

final class PrimerTextField: UITextField {

    enum Validation: Equatable {
        case valid, invalid(_ error: Error?), notAvailable

        static func == (lhs: Validation, rhs: Validation) -> Bool {
            switch (lhs, rhs) {
            case (.valid, .valid):
                lhs == rhs
            case (.invalid, .invalid):
                lhs == rhs
            case (.notAvailable, .notAvailable):
                lhs == rhs
            default:
                false
            }
        }
    }

    override var delegate: UITextFieldDelegate? {
        get {
            super.delegate
        }
        set {
            if let primerTextFieldView = newValue as? PrimerTextFieldView {
                super.delegate = primerTextFieldView
            }
        }
    }

    // Sensitive entry (card number, CVV, …) is held as a mutable byte buffer rather than a
    // `String` so it can be zeroed in place on `wipe()`. A `String`'s backing storage cannot be
    // reliably overwritten — reassigning only releases it, leaving the secret in freed memory.
    private var secureStorage: [UInt8]?

    var internalText: String? {
        get { secureStorage.flatMap { String(bytes: $0, encoding: .utf8) } }
        set {
            zeroSecureStorage()
            secureStorage = newValue.map { Array($0.utf8) }
        }
    }

    override var text: String? {
        get {
            "****"
        }
        set {
            super.text = newValue
            internalText = super.text
        }
    }

    var isEmpty: Bool {
        (internalText ?? "").isEmpty
    }

    func wipe() {
        zeroSecureStorage()
        secureStorage = nil
        super.text = nil
    }

    // Overwrites the live secret buffer in place before release. `memset_s` is guaranteed not to
    // be optimised away, unlike a plain loop or a reassignment.
    private func zeroSecureStorage() {
        guard secureStorage?.isEmpty == false else { return }
        secureStorage?.withUnsafeMutableBytes { raw in
            guard let base = raw.baseAddress else { return }
            memset_s(base, raw.count, 0, raw.count)
        }
    }
}
