//
//  ShowcaseEnums.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Enumeration of available showcase categories
@available(iOS 15.0, *)
enum ShowcaseCategory: String, CaseIterable {
    case architecture = "Architecture"
    case styling = "Styling"
    case layouts = "Layouts"
    case interactive = "Interactive"
}