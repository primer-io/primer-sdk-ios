//
//  ShowcaseEnums.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import Foundation

/// Enumeration of available showcase sections
@available(iOS 15.0, *)
enum ShowcaseSection: String, CaseIterable {
    case layouts = "Layout Configurations"
    case styling = "Styling Variations"
    case interactive = "Interactive Features"
    case advanced = "Advanced Customization"
}