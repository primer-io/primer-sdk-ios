//
//  TextFieldProps.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

struct TextFieldProps: UI {
    let label: String
    let value: String
    let placeholder: String?
    let maxLength: Int? // TODO: not implemented
    let textAlign: TextAlign
    let autoComplete: AutoComplete?
    let keyboardType: KeyboardType?
	
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.label = try container.decode(String.self, forKey: .label)
        self.value = try container.decode(String.self, forKey: .value)
        self.placeholder = try container.decodeIfPresent(String.self, forKey: .placeholder)
        self.maxLength = try container.decodeIfPresent(Int.self, forKey: .maxLength)
        self.textAlign = (try? container.decode(TextAlign.self, forKey: .textAlign)) ?? .start
        self.autoComplete = try container.decodeIfPresent(AutoComplete.self, forKey: .autoComplete)
        self.keyboardType = try container.decodeIfPresent(KeyboardType.self, forKey: .keyboardType)
    }
}
