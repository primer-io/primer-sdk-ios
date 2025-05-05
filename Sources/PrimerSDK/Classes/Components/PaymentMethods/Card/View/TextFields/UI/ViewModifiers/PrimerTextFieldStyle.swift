//
//  PrimerTextFieldStyle.swift
//
//
//  Created by Boris on 29. 4. 2025..
//

import SwiftUI

public struct PrimerTextFieldStyle: ViewModifier {
    var isError: Bool = false

    public func body(content: Content) -> some View {
        content
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isError ? Color.red : Color.clear, lineWidth: isError ? 1 : 0)
            )
    }
}

public extension View {
    func primerTextFieldStyle(isError: Bool = false) -> some View {
        modifier(PrimerTextFieldStyle(isError: isError))
    }
}
