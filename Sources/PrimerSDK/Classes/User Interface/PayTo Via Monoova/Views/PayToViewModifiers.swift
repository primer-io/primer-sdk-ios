//
//  PayToViewModifiers.swift
//  IQKeyboardManagerSwift
//
//  Created by Jack Newcombe on 11/09/2024.
//

import SwiftUI

let titleTextColor = Color(red: 0x21 / 255, green: 0x21 / 255, blue: 0x21 / 255)
let bodyTextColor = Color(red: 0x61 / 255, green: 0x61 / 255, blue: 0x61 / 255)

struct TitleTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(titleTextColor)
            .padding(.bottom, 8)
    }
}

extension Text {
    func titleText() -> some View {
        modifier(TitleTextModifier())
    }
}

struct SubtitleTextModifier: ViewModifier {

    let bolded: Bool

    func body(content: Content) -> some View {
        content
            .font(.system(size: 16, weight: bolded ? .bold : .regular))
            .foregroundColor(titleTextColor)
            .padding(.bottom, 8)
    }
}

extension Text {
    func subtitleText(bolded: Bool = false) -> some View {
        modifier(SubtitleTextModifier(bolded: bolded))
    }
}

struct BodyTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 14))
            .foregroundColor(bodyTextColor)
    }
}

extension Text {
    func bodyText() -> some View {
        modifier(BodyTextModifier())
    }
}

struct UserDetailsControlModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .foregroundColor(bodyTextColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(bodyTextColor, lineWidth: 0.5)
            )
    }
}

extension View {
    func userDetailsControl() -> some View {
        modifier(UserDetailsControlModifier())
    }
}
