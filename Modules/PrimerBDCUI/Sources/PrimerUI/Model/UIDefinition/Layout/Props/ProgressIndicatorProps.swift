//
//  ProgressIndicatorProps.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@_spi(PrimerInternal) import PrimerFoundation

struct ProgressIndicatorProps: UI {
    let size: ProgressIndicatorSize
}

enum ProgressIndicatorSize: String, SingleValueContained {
    case small
    case medium
    case large
	
    @available(iOS 16.0, *)
    func callAsFunction() -> ControlSize {
        switch self {
        case .small: .small
        case .medium: .regular
        case .large: .large
        }
    }
}
