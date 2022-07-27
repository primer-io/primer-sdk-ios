//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

#if canImport(UIKit)

public enum PrimerSessionIntent: String, Encodable {
    case checkout = "CHECKOUT"
    case vault = "VAULT"
}

#endif
