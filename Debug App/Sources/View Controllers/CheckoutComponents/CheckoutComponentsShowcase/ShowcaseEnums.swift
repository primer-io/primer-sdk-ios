//
//  ShowcaseEnums.swift
//  Debug App
//
//  Created on 26.6.25.
//

import Foundation

/// Enumeration of available showcase categories
@available(iOS 15.0, *)
enum ShowcaseCategory: String, CaseIterable {
    case architecture = "Architecture"
    case styling = "Styling"
    case layouts = "Layouts"
    case interactive = "Interactive"
}