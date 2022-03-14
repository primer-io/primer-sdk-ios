//
//  Identifiable.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 14/02/22.
//  Copyright © 2022 Primer API ltd, Inc. All rights reserved.
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
