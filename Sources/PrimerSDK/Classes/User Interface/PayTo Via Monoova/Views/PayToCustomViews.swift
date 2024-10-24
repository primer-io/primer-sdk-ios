//
//  PayToCustomViews.swift
//  IQKeyboardManagerSwift
//
//  Created by Jack Newcombe on 11/09/2024.
//

import SwiftUI

struct PayToTitledView<Content: View>: View {

    let title: String

    let content: () -> Content

    init(title: String,
         @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(title).titleText()
            content()
        }
        .frame(maxWidth: .infinity)
        .padding(12)
    }
}

struct BulletPointText: View {

    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("∙").bodyText()
            Text(text).bodyText()
        }
        .padding(.bottom, 2)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, maxHeight: 48)
            .background(Color.black)
            .foregroundColor(.white) // TOODO: color var
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, maxHeight: 48)
            .background(Color.white) // TOODO: color var
            .foregroundColor(.black) // TOODO: color var
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct PrimaryActionButton: View {

    let text: String

    let action: () -> Void

    var body: some View {
        Button(text) {
            action()
        }
        .buttonStyle(PrimaryButtonStyle())
    }
}

struct SecondaryActionButton: View {

    let text: String

    let action: () -> Void

    var body: some View {
        Button(text) {
            action()
        }
        .buttonStyle(SecondaryButtonStyle())
    }
}

struct PickerButton: View {

    @State var selection: String

    var body: some View {
        Button {
            print("Test")
        } label: {
            HStack {
                Text("Account Number & BSB")
                Spacer()
                Image(systemName: "chevron.down")
            }
            .userDetailsControl()
        }

    }
}

struct CalloutText: View {

    let text: String

    let icon: String?

    init(text: String, icon: String? = nil) {
        self.text = text
        self.icon = icon
    }

    var body: some View {
        HStack {
            if let icon = icon {
                Image(icon)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding(.trailing, 8)
            }
            Text(text)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding([.top, .bottom], 8)
        .background(Color.gray.opacity(0.1))
    }
}
