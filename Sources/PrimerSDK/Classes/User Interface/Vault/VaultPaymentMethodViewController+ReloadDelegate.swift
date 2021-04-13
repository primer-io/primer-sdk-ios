//
//  VaultPaymentMethodViewController+CardFormViewControllerDelegate.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 04/01/2021.
//

#if canImport(UIKit)

import UIKit

extension VaultPaymentMethodViewController: ReloadDelegate {

    func reload() {
        let viewModel: VaultPaymentMethodViewModelProtocol = DependencyContainer.resolve()
        viewModel.reloadVault { [weak self] _ in
            DispatchQueue.main.async { self?.subView.render() }
        }
    }

}

#endif
