//
//  MerchantHeadlessCheckoutKlarnaViewController+TableView.swift
//  Debug App
//
//  Created by Stefan Vrancianu on 29.01.2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import UIKit

// MARK: - UITableViewDelegate
extension MerchantHeadlessCheckoutKlarnaViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        categoriesContainerView.isHidden = true
        showLoader()
        createPaymentView(category: paymentCategories[indexPath.row])
    }
}

// MARK: - UITableViewDataSource
extension MerchantHeadlessCheckoutKlarnaViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return paymentCategories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UITableViewCell.self), for: indexPath)
        cell.textLabel?.text = paymentCategories[indexPath.row].name
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

// MARK: - UITextFieldDelegate
extension MerchantHeadlessCheckoutKlarnaViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let datePicker = UIDatePicker()
        datePicker.sizeToFit()
        datePicker.datePickerMode = .dateAndTime
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .automatic
        }
        datePicker.addTarget(self, action: #selector(datePickerValueChanged(_:)), for: .valueChanged)
        
        if textField == customerAccountRegistrationTextField {
            registrationFieldActive = true
            
            textField.inputView = datePicker
            textField.inputView?.frame.size = CGSize(width: view.frame.width, height: 200.0)
        } else if textField == customerAccountLastModifiedTextField {
            registrationFieldActive = false
            
            textField.inputView = datePicker
            textField.inputView?.frame.size = CGSize(width: view.frame.width, height: 200.0)
        }
    }
}
