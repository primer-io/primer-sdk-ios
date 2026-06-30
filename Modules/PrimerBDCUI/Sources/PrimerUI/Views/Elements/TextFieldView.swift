//
//  TextFieldView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

struct TextFieldView: View {
    let label: String
    let placeholder: String
    var secure = false
    let text: String
    let autoComplete: AutoComplete?
    let keyboardType: KeyboardType?
    
    let onChange: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
			
            Group {
                if secure {
                    SecureField(placeholder, text: Binding<String>(get: { text }, set: { onChange($0) }))
                } else {
                    TextField(placeholder, text: Binding<String>(get: { text }, set: { onChange($0) }))
                }
            }
			
            Divider()
                .frame(height: 1)
        }
        .textContentType(autoComplete.flatMap(UITextContentType.init))
        .autocorrectionDisabled()
        .keyboardType(keyboardType.map(UIKeyboardType.init) ?? .default)
    }
}
