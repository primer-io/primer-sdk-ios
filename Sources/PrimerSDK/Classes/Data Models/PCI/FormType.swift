//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

#if canImport(UIKit)

import Foundation

public enum PrimerFormType: String, CaseIterable {
    case bankAccount
    case name
    case iban
    case email
    case address
    case cardForm
}

#endif
