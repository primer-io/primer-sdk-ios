//
//  PrimerErrorTextStyle.swift
//
//
//  Created by Boris on 29. 4. 2025..
//

import SwiftUI

public struct PrimerErrorTextStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.caption)
            .foregroundColor(.red)
    }
}

public extension View {
    func primerErrorTextStyle() -> some View {
        modifier(PrimerErrorTextStyle())
    }
}
