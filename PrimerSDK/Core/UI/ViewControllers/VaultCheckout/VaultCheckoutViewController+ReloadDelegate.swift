//
//  VaultCheckoutViewController+VaultPaymentMethodViewControllerDelegate.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 04/01/2021.
//

import UIKit

extension VaultCheckoutViewController: ReloadDelegate {
    
    func reload() {
        self.vaultCheckoutView.tableView.reloadData()
    }
    
}
