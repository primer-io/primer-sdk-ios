//
//  DirectCheckoutViewController+TableView.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 11/01/2021.
//

import UIKit

extension DirectCheckoutViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.paymentMethods.count
    }
    
    // There is just one row in every section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    // Set the spacing between sections
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 12.0
    }
    
    // Make the background color show through
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell5")
        
        let method = viewModel.paymentMethods[indexPath.section]
        let methodView = PaymentMethodComponent.init(frame: view.frame, method: method)
    
        cell.layer.cornerRadius = 12.0
        cell.contentView.addSubview(methodView)
        methodView.pin(to: cell.contentView)
        cell.frame = cell.frame.inset(by: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        cell.separatorInset = UIEdgeInsets.zero
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let vm = viewModel.paymentMethods[indexPath.section]
        
        switch vm.type {
        case .APPLE_PAY: router.show(.applePay)
        case .GOOGLE_PAY: break
        case .PAYMENT_CARD: router.show(.cardForm)
        case .PAYPAL: router.show(.oAuth)
        case .GOCARDLESS_MANDATE: break
        }
    }
}

