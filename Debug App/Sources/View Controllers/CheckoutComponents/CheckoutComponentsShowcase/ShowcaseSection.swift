//
//  ShowcaseSection.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI

/// Reusable showcase section wrapper
@available(iOS 15.0, *)
struct ShowcaseSection<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content
    
    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}