//
//  DateFormatter.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public extension DateFormatter {

    /**
     The provided function sets the `dateFormat` property of DateFormatter.

     Format: `yyyy-MM-dd'T'HH:mm:ss`

     - Returns: The DateFormatter instance.
     */
    func withVoucherExpirationDateFormat() -> DateFormatter {
        self.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return self
    }
}

public extension DateFormatter {

    /**
     The provided function sets the `style` of `date` and `time` property of DateFormatter.

     Format: `Sep 16, 2022 at 11:46 AM`

     - Returns: The DateFormatter instance.
     */
    func withExpirationDisplayDateFormat() -> DateFormatter {
        self.dateStyle = .medium
        self.timeStyle = .short
        return self
    }

}
