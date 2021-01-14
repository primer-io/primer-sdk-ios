//
//  String+Localisation.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 11/01/2021.
//

import Foundation

extension String {
    func localized(comment: String? = nil) -> String {
        return NSLocalizedString(
            self,
            tableName: "Localizable",
            bundle: .main,
            value: self,
            comment: comment ?? self
        )
    }
}
