//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

#if canImport(UIKit)

import UIKit

///
/// Used to identify a PrimerButton if needed
/// For implementation example check PrimerButton.swift
///
protocol Identifiable where Self: UIView {
    
    /// The identifier
    var id: String? { get set }
}

#endif
