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
    internal private(set) var dataSource: [Bank] {
        didSet {
            tableView.reloadData()
        }
    }
    
    internal lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }

        tableView.rowHeight = 41
        tableView.register(BankTableViewCell.self, forCellReuseIdentifier: BankTableViewCell.identifier)
        tableView.dataSource = self
        return tableView
    }()
    
    internal lazy var searchBankTextField: PrimerSearchTextField? = {
        let textField = PrimerSearchTextField(frame: .zero)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.heightAnchor.constraint(equalToConstant: 35).isActive = true
        textField.delegate = self
        textField.backgroundColor = UIColor(red: 36.0/255, green: 42.0/255, blue: 47.0/255, alpha: 0.03)
        textField.borderStyle = .none
        textField.layer.cornerRadius = 3.0
        textField.font = UIFont.systemFont(ofSize: 16.0)
        textField.placeholder = NSLocalizedString("search-bank-placeholder",
                                                        tableName: nil,
                                                        bundle: Bundle.primerResources,
                                                        value: "Search bank",
                                                        comment: "Search bank - Search bank textfield placeholder")
        textField.rightViewMode = .always
        return textField
    }()
    
    init(banks: [Bank]) {
        self.banks = banks
        self.dataSource = banks
        super.init()
    }
}

extension BankSelectorViewModel: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = dataSource[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "BankTableViewCell", for: indexPath) as! BankTableViewCell
        cell.configure(viewModel: viewModel)
        return cell
    }
}

extension BankSelectorViewModel: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var query: String
        
        if string.isEmpty {
            query = String((textField.text ?? "").dropLast())
        } else {
            query = (textField.text ?? "") + string
        }
        
        if query.isEmpty {
            dataSource = banks
            return true
        }
        
        var bankResults: [Bank] = []
        
        for bank in banks {
            if bank.name?.lowercased().contains(query.lowercased()) == true {
                bankResults.append(bank)
            }
        }
        
        dataSource = bankResults
        
        return true
    }
}

#endif
