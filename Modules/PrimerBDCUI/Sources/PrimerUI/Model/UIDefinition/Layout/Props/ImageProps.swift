//
//  ImageProps.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation
import SwiftUI

struct ImageProps: UI {
    let source: String
    let fallback: String?
    let contentMode: ContentMode?
    let width: Size
    let height: Size
	
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.source = try container.decode(String.self, forKey: .source)
        self.fallback = try container.decodeIfPresent(String.self, forKey: .fallback)
        self.contentMode = try container.decodeIfPresent(ContentMode.self, forKey: .contentMode) ?? .scaleAspectFit
        let width = (try? container.decode(CodableValue.self, forKey: .width)) ?? .string("wrap")
        let height = (try? container.decode(CodableValue.self, forKey: .height)) ?? .string("wrap")
        self.width = Size(codableValue: width)
        self.height = Size(codableValue: height)
    }
}

enum ContentMode: String, UI, SingleValueContained {
    case scaleAspectFit = "SCALE_ASPECT_FIT"
    case scaleAspectFill = "SCALE_ASPECT_FILL"
	
    func callAsFunction() -> SwiftUI.ContentMode? {
        switch self {
        case .scaleAspectFit: .fit
        case .scaleAspectFill: .fill
        }
    }
}
