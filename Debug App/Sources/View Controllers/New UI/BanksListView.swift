//
//  BanksListView.swift
//  Debug App
//
//  Created by Alexandra Lovin on 16.11.2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import SwiftUI

struct BanksListView: View {
    let paymentMethodName: String
    @ObservedObject var banksModel: BanksListModel
    private var didSelectBank: ((String) -> Void)
    private var didFilterByText: ((String) -> Void)

    @State private var filterText = ""

    init(paymentMethodName: String, banksModel: BanksListModel, didSelectBank: @escaping ((String) -> Void), didFilterByText: @escaping ((String) -> Void)) {
        self.paymentMethodName = paymentMethodName
        self.banksModel = banksModel
        self.didSelectBank = didSelectBank
        self.didFilterByText = didFilterByText
    }
    var body: some View {
        HStack {
            Text("\(paymentMethodName)")
        }
        Spacer()
        Text("Choose your bank")
        SearchBar(text: $filterText.didSet { text in
            didFilterByText(text)
        })
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
        BanksListView(paymentMethodName: "Ideal", banksModel: BanksListModel(), didSelectBank: { _ in }, didFilterByText: { _ in })
    }
}

