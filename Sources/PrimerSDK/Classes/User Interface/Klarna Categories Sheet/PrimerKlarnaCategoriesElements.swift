//
//  PrimerKlarnaCategoriesElements.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import UIKit

final class SharedUIViewWrapper: ObservableObject {
    @Published var uiView: UIView?
}

struct DynamicUIViewRepresentable: UIViewRepresentable {
    @ObservedObject var wrapper: SharedUIViewWrapper

    func makeUIView(context: Context) -> UIView {
        return wrapper.uiView ?? UIView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        uiView.subviews.forEach { $0.removeFromSuperview() }

        if let newView = wrapper.uiView {
            if newView.superview == nil {
                uiView.addSubview(newView)
                newView.frame = uiView.bounds
            }
        }
    }
}

struct KlarnaCategoryButton: View {
    @ObservedObject var sharedWrapper: SharedUIViewWrapper

    var isSelected: Bool
    let title: String
    let action: () -> Void
    let klarnaCategoryImage = UIImage.klarnaCategory ?? UIImage()
    let checkmarkImage = UIImage.checkmark?.withRenderingMode(.alwaysTemplate) ?? UIImage()

    var body: some View {
        VStack {
            HStack {
                Image(uiImage: klarnaCategoryImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                Text(title)
                    .foregroundColor(.black)
                    .fontWeight(.medium)
                Spacer()
                if isSelected {
                    Image(uiImage: checkmarkImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 15, height: 15)
                        .padding(5)
                        .foregroundColor(.blue)
                }
            }
            .background(GeometryReader { geometry in
                Color.clear
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .background(Color.red.opacity(0.001))
                    .onTapGesture {
                        withAnimation {
                            action()
                        }
                    }
            })

            if isSelected {
                DynamicUIViewRepresentable(wrapper: sharedWrapper)
                    .frame(height: 240)
                    .addAccessibilityIdentifier(identifier: AccessibilityIdentifier.KlarnaComponent.paymentViewContainer.rawValue)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.white)
        .cornerRadius(5)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(isSelected ? Color.blue.opacity(0.8) : Color.gray.opacity(0.25), lineWidth: isSelected ? 2 : 1)
        )
    }
}

struct ContinueButton: View {
    @Binding var isActive: Bool

    let title: String
    let continuePressed: () -> Void

    var body: some View {
        Button {
            continuePressed()
        } label: {
            Text(title)
                .font(.headline)
                .foregroundColor(isActive ? .white : .black.opacity(0.2))
                .frame(maxWidth: .infinity)
                .padding()
                .background(isActive ? Color.blue : Color.gray.opacity(0.2))
                .cornerRadius(5)
        }
        .disabled(!isActive)
    }
}

extension View {
    @ViewBuilder func addAccessibilityIdentifier(identifier: String) -> some View {
        if #available(iOS 14.0, *) {
            accessibilityIdentifier(identifier)
        } else {
            accessibility(identifier: identifier)
        }
    }
}
