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
    @ObservedObject var banks = BanksListModel()
    init(paymentMethodName: String, banks: BanksListModel = BanksListModel()) {
        self.paymentMethodName = paymentMethodName
        self.banks = banks
    }
    var body: some View {
        Text("\(paymentMethodName)")
        Text("Choose your bank")
        ScrollView(.vertical) {
            List(banks.banks, id: \.id) { bank in
                HStack {
                    Text(bank.name)
                    Image(systemName: "arrow.right")
                }
                }
            }
    }
}

struct BanksListView_Previews: PreviewProvider {
    static var previews: some View {
        BanksListView(paymentMethodName: "Ideal", banks: BanksListModel())
    }
}
