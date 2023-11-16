//
//  BanksListView.swift
//  Debug App
//
//  Created by Alexandra Lovin on 16.11.2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import SwiftUI

struct PaymentMethodModel {
    let name: String
    let logo: UIImage?
}

struct BanksListView: View {
    let paymentMethodModel: PaymentMethodModel
    private let metrics = Metrics()

    @ObservedObject var banksModel: BanksListModel

    private var didSelectBank: ((String) -> Void)
    private var didFilterByText: ((String) -> Void)
    @State private var filterText = ""

    init(paymentMethodModel: PaymentMethodModel, banksModel: BanksListModel, didSelectBank: @escaping ((String) -> Void), didFilterByText: @escaping ((String) -> Void)) {
        self.paymentMethodModel = paymentMethodModel
        self.banksModel = banksModel
        self.didSelectBank = didSelectBank
        self.didFilterByText = didFilterByText
    }

    var body: some View {
        Spacer()
        HStack {
            Text("\(paymentMethodModel.name)")
            if let image = paymentMethodModel.logo {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: metrics.imageSize.width, height: metrics.imageSize.height)
            }
        }
        Divider()

        Text("Choose your bank")
            .multilineTextAlignment(.leading)

        SearchBar(text: $filterText.didSet { text in
            didFilterByText(text)
        })

        Divider()

        List(banksModel.banks, id: \.id) { bank in
            Button {
                didSelectBank(bank.id)
            } label: {
                HStack(spacing: metrics.hStackSpacing) {
                    HStack {
                            if let imageUrlString = bank.iconUrlStr,
                               let imageUrl = URL(string: imageUrlString) {
                                image(url: imageUrl)
                            }
                        Text(bank.name)
                    }
                    .frame(height: metrics.cellHeight)
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .padding(.leading, metrics.hStackLeading)
                .padding(.trailing, metrics.hStackTrailing)
            }
        }
        .padding(.top, 0)
    }

    private func image(url: URL) -> some View {
        ImageViewWithUrl(
            url: url,
            placeholder: {
              Image("questionmark.circle")
                    .frame(width: metrics.imageSize.width, height: metrics.imageSize.height)
            },
            image: {
                $0.resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: metrics.imageSize.width, height: metrics.imageSize.height)
            }
          )
    }
}

extension BanksListView {
    private struct Metrics {
        let imageSize: CGSize = CGSize(width: 30, height: 30)
        let hStackSpacing: CGFloat = 5
        let cellHeight: CGFloat = 40
        let hStackLeading: CGFloat = 10
        let hStackTrailing: CGFloat = 0
    }
}

extension Binding {
    func didSet(execute: @escaping (Value) -> Void) -> Binding {
        return Binding(
            get: { self.wrappedValue },
            set: {
                self.wrappedValue = $0
                execute($0)
            }
        )
    }
}

extension BanksListView {
    struct SearchBar: View {
        @Binding var text: String
        @State private var isEditing = false

        var body: some View {
            HStack {

                TextField("Search bank", text: $text)
                    .padding(7)
                    .padding(.horizontal, 25)
                    .padding(.horizontal, 10)
                    .onTapGesture {
                        self.isEditing = true
                    }
                if isEditing {
                    Button(action: {
                        self.isEditing = false
                        self.text = ""
                    }) {
                        Text("Cancel")
                    }
                    .padding(.trailing, 10)
                    .transition(.move(edge: .trailing))
                    .animation(.default)
                }
            }
        }
    }
}

struct BanksListView_Previews: PreviewProvider {
    static var previews: some View {
        BanksListView(paymentMethodModel: PaymentMethodModel(name: "ideal", logo: nil), banksModel: BanksListModel(), didSelectBank: { _ in }, didFilterByText: { _ in })
    }
}

