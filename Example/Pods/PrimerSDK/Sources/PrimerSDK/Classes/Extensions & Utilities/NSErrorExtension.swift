//
//  NSErrorExtension.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 04/05/22.
//

import Foundation

extension NSError {
    static var emptyDescriptionError: NSError {
        NSError(domain: "", code: 0001)
    }
}
