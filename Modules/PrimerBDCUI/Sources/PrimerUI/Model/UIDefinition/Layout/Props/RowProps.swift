//
//  RowProps.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation
import SwiftUI

struct RowProps: Props {
    let alignItems: AlignItems
    let padding: CodableValue?
    let spacing: CodableValue?
    let justifyContent: JustifyContent
    let width: Size
    let height: Size
    let backgroundColor: String?
    let borderRadius: Double?
    let borderColor: String?
    let borderWidth: Double?

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        alignItems = (try? container.decodeIfPresent(AlignItems.self, forKey: .alignItems)) ?? .center
        padding = try container.decodeIfPresent(CodableValue.self, forKey: .padding)
        spacing = try container.decodeIfPresent(CodableValue.self, forKey: .spacing)
        justifyContent = (try? container.decode(JustifyContent.self, forKey: .justifyContent)) ?? .flexStart
        let width = (try? container.decode(CodableValue.self, forKey: .width)) ?? .string("wrap")
        let height = (try? container.decode(CodableValue.self, forKey: .height)) ?? .string("wrap")
        self.width = Size(codableValue: width)
        self.height = Size(codableValue: height)
        backgroundColor = try container.decodeIfPresent(String.self, forKey: .backgroundColor)
        borderRadius = try container.decodeIfPresent(Double.self, forKey: .borderRadius)
        borderColor = try container.decodeIfPresent(String.self, forKey: .borderColor)
        borderWidth = try container.decodeIfPresent(Double.self, forKey: .borderWidth)
    }
}

extension RowProps {
    var verticalAlignment: VerticalAlignment {
        switch alignItems {
        case .center: .center
        case .stretch: .center
        case .flexStart: .top
        }
    }
    	
    var horizontalAlignment: HorizontalAlignment {
        switch justifyContent {
        case .flexStart, .spaceBetween: .leading
        case .center: .center
        }
    }
	
    var frameAlignment: Alignment {
        Alignment(horizontal: horizontalAlignment, vertical: .center)
    }
}
