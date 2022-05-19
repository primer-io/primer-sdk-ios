//
//  Strings.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 10/02/22.
//  Copyright © 2022 Primer API ltd, Inc. All rights reserved.
//

import Foundation

struct Strings {
    
    enum PrimerButton {
        static let title = NSLocalizedString(
            "PRIMER_BUTTON_TITLE_DEFAULT",
            bundle: Bundle.primerResources,
            comment: "The title of the primer deafult button")
    }
    
    enum Generic {
        static let somethingWentWrong = NSLocalizedString(
            "primer-error-screen",
            bundle: Bundle.primerResources,
            value: "Something went wrong, please try again.",
            comment: "A generic error message that is displayed on the error view")
    }
    
}
