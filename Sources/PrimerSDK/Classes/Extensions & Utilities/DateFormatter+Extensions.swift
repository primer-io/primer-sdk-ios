//
//  DateFormatter+Extensions.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 28/08/22.
//

import Foundation

internal extension DateFormatter {
    
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
