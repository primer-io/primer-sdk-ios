//
//  PrimerTextFieldStyle.swift
//  
//
//  Created by Boris on 29. 4. 2025..
//


import SwiftUI

public struct PrimerTextFieldStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
}

public extension View {
    func primerTextFieldStyle() -> some View {
        modifier(PrimerTextFieldStyle())
    }
}
