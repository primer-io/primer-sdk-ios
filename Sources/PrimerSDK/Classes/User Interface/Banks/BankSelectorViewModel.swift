//
//  BankSelectorViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 25/10/21.
//

#if canImport(UIKit)

import UIKit

class BankSelectorViewModel: NSObject {
    
    internal private(set) var banks: [Bank]
    
    init(banks: [Bank]) {
        self.banks = banks
        super.init()
    }
}

extension BankSelectorViewModel: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return banks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = banks[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "BankTableViewCell", for: indexPath) as! BankTableViewCell
        cell.configure(viewModel: viewModel)
        return cell
    }
}

#endif
