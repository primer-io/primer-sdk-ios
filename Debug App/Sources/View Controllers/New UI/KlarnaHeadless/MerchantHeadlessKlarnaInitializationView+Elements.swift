//
//  MerchantHeadlessKlarnaInitializationView+Elements.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit
import SwiftUI

class SharedUIViewWrapper: ObservableObject {
    @Published var uiView: UIView?
}

struct DynamicUIViewRepresentable: UIViewRepresentable {
    @ObservedObject var wrapper: SharedUIViewWrapper

    func makeUIView(context: Context) -> UIView {
        return wrapper.uiView ?? UIView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let newView = wrapper.uiView {
            uiView.addSubview(newView)
            newView.frame = uiView.bounds
        }
    }
}

struct RadioButtonView: View {
    var isSelected: Bool
    let title: String
    let action: () -> Void

    var body: some View {
        HStack {
            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                .foregroundColor(isSelected ? .purple : .gray)
                .font(.system(size: 18))
            Text(title)
        }
        .onTapGesture(perform: action)
    }
}

struct KlarnaButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .cornerRadius(10)
        }
    }
}

struct SnackbarView: View {
    let message: String

    var body: some View {
        Text(message)
            .padding()
            .background(Color.black.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}
