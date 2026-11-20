//
//  RadioButtonView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

struct RadioButtonCircle: View {
    private let isSelected: Bool
    private let color: Color
    
    private var fillColor: Color { isSelected ? color : .clear }
    
    init(isSelected: Bool, color: Color) {
        self.isSelected = isSelected
        self.color = color
    }
    
    var body: some View {
        Circle()
            .strokeBorder(color, lineWidth: 2.5)
            .background(Circle().fill(fillColor).padding(4))
            .frame(width: 16, height: 16)
    }
}

#if DEBUG
    #Preview {
        RadioButtonCircle(isSelected: true, color: .red)
    }
#endif
