//
//  TextProps.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

struct TextProps: UI {
    let text: String
    let textStyle: String?
    let color: String?
    let textAlign: TextAlign
		
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.text = try container.decode(String.self, forKey: .text)
        self.textStyle = try container.decodeIfPresent(String.self, forKey: .textStyle)
        self.color = try container.decodeIfPresent(String.self, forKey: .color)
        self.textAlign = (try? container.decodeIfPresent(TextAlign.self, forKey: .textAlign)) ?? .start
    }
}

enum TextAlign: String, SingleValueContained {
    case start
    case end
    case center
    
    func callAsFunction() -> TextAlignment {
        switch self {
        case .start: .leading
        case .end: .trailing
        case .center: .center
        }
    }
}
