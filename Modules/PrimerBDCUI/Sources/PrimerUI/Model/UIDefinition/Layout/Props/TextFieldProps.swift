//
//  TextFieldProps.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation

struct TextFieldProps: UI {
    let label: String
    let value: String
    let placeholder: String?
    let maxLength: Int?
    let textAlign: TextAlign
    let autoComplete: AutoComplete?
    let keyboardType: KeyboardType?
	
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        label = try container.decode(String.self, forKey: .label)
        value = try container.decode(String.self, forKey: .value)
        placeholder = try container.decodeIfPresent(String.self, forKey: .placeholder)
        maxLength = try container.decodeIfPresent(Int.self, forKey: .maxLength)
        textAlign = (try? container.decode(TextAlign.self, forKey: .textAlign)) ?? .start
        autoComplete = try container.decodeIfPresent(AutoComplete.self, forKey: .autoComplete)
        keyboardType = try container.decodeIfPresent(KeyboardType.self, forKey: .keyboardType)
    }
}
