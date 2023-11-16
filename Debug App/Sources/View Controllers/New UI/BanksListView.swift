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
                    .frame(width: 30, height: 30)
            }
        }
        Divider()
        Text("Choose your bank")
        SearchBar(text: $filterText.didSet { text in
            didFilterByText(text)
        })
        Divider()
        List(banksModel.banks, id: \.id) { bank in
            Button {
                didSelectBank(bank.id)
            } label: {
                HStack(spacing: 5) {
                    HStack {
                        if #available(iOS 14.0, *) {
                            if let imageUrlString = bank.iconUrlStr,
                               let imageUrl = URL(string: imageUrlString) {
                                ImageViewWithUrl(
                                    url: imageUrl,
                                    placeholder: {
                                      Image("placeholder")
                                            .frame(width: 40)
                                    },
                                    image: {
                                        $0.resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 30, height: 30)
                                    }
                                  )
                            }
                        }
                        Text(bank.name)
                    }
                    .frame(height: 40)
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .padding(.leading, 10)
                .padding(.trailing, 0)
            }
        }
        .padding(.top, 0)
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

struct BanksListView_Previews: PreviewProvider {
    static var previews: some View {
        BanksListView(paymentMethodModel: PaymentMethodModel(name: "ideal", logo: nil), banksModel: BanksListModel(), didSelectBank: { _ in }, didFilterByText: { _ in })
    }
}

