//
//  VaultPaymentMethodViewController+CardFormViewControllerDelegate.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 04/01/2021.
//

import UIKit

extension VaultPaymentMethodViewController: ReloadDelegate {
    
    func reload() {
        viewModel.reloadVault() { [weak self] error in
            DispatchQueue.main.async { self?.subView.render() }
        }
    }
    
}

