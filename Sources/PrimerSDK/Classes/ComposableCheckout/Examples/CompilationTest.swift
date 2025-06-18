//
//  CompilationTest.swift
//
//
//  Created on 18.06.2025.
//

import SwiftUI

/// Simple test to verify that our new modifier system compiles correctly
@available(iOS 15.0, *)
struct CompilationTestView: View {
    var body: some View {
        VStack {
            // Test direct component access
            PrimerComponents.PrimerCardNumberInput(
                modifier: PrimerModifier.fillMaxWidth().padding(.all, 16),
                label: "Test Card Number"
            ) { _ in }

            // Test modifier chaining
            Text("Test")
                .primerModifier(
                    PrimerModifier()
                        .fillMaxWidth()
                        .background(.blue)
                        .cornerRadius(8)
                )
        }
    }
}

#Preview {
    if #available(iOS 15.0, *) {
        CompilationTestView()
    } else {
        // Fallback on earlier versions
    }
}
