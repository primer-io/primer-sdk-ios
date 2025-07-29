//
//  Identifiable.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

///
/// Used to identify a PrimerButton if needed
/// For implementation example check PrimerButton.swift
///
protocol Identifiable where Self: UIView {

    /// The identifier
    var id: String? { get set }
}
