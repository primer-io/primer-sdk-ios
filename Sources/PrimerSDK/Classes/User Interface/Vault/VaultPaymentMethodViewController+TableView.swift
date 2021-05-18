#if canImport(UIKit)

import UIKit

extension VaultPaymentMethodViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()

        headerView.backgroundColor = UIColor.clear

        return headerView
    }

    @objc private func showCardForm(_ sender: UIButton) {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        let router: RouterDelegate = DependencyContainer.resolve()
        router.show(.form(type: .cardForm(theme: theme)))
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewModel: VaultPaymentMethodViewModelProtocol = DependencyContainer.resolve()
        
        if indexPath.row == viewModel.paymentMethods.count {
            return
        }

        tableView.deselectRow(at: indexPath, animated: true)

        if !showDeleteIcon {

            viewModel.selectedId = viewModel.paymentMethods[indexPath.row].token ?? ""

            tableView.reloadData()

        } else {

            guard let methodId = viewModel.paymentMethods[indexPath.row].token else { return }

            let alert = AlertController(
                title: NSLocalizedString("primer-delete-alert-title",
                                         tableName: nil,
                                         bundle: Bundle.primerResources,
                                         value: "Do you want to delete this payment method?",
                                         comment: "Do you want to delete this payment method? - Delete alert title"),
                message: "",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(
                                title: NSLocalizedString("primer-alert-button-cancel",
                                                         tableName: nil,
                                                         bundle: Bundle.primerResources,
                                                         value: "Cancel",
                                                         comment: "Cancel - Alert button cancel"),
                                style: .cancel,
                                handler: nil))

            alert.addAction(UIAlertAction(
                                title: NSLocalizedString("primer-alert-button-delete",
                                                         tableName: nil,
                                                         bundle: Bundle.primerResources,
                                                         value: "Delete",
                                                         comment: "Delete - Alert button delete"),
                                style: .destructive,
                                handler: { [weak self] _ in
                                    self?.deletePaymentMethod(methodId)
                                }))

            alert.show()
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    private func deletePaymentMethod(_ paymentMethodToken: String) {
        let viewModel: VaultPaymentMethodViewModelProtocol = DependencyContainer.resolve()
        viewModel.deletePaymentMethod(with: paymentMethodToken, and: { [weak self] _ in
            DispatchQueue.main.async {
                self?.subView.tableView.reloadData()
                
                // Going back if no payment method remains
                if viewModel.paymentMethods.isEmpty {
                    self?.cancel()
                }
            }
        })
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let viewModel: VaultPaymentMethodViewModelProtocol = DependencyContainer.resolve()
        
        // TODO: Only return the number of saved payment instruments while we figure the design
        return viewModel.paymentMethods.count
        
        // return viewModel.paymentMethods.count + 1 /* "Add card" button */
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        let viewModel: VaultPaymentMethodViewModelProtocol = DependencyContainer.resolve()
        
        let cell = UITableViewCell()

        if indexPath.row == viewModel.paymentMethods.count {
            let addButton = UIButton()

            addButton.setTitle(theme.content.vaultPaymentMethodView.addButtonText, for: .normal)
            addButton.setTitleColor(theme.colorTheme.tint1, for: .normal)
            addButton.setTitleColor(theme.colorTheme.disabled1, for: .highlighted)
            addButton.contentHorizontalAlignment = .left
            addButton.addTarget(self, action: #selector(showCardForm), for: .touchUpInside)

            addButton.translatesAutoresizingMaskIntoConstraints = false

            cell.selectionStyle = .none
            cell.contentView.addSubview(addButton)

            addButton.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 10).isActive = true
            addButton.centerYAnchor.constraint(equalTo: cell.centerYAnchor).isActive = true

            return cell
        }

        let token = viewModel.paymentMethods[indexPath.row]

        let cardView = CardButton()

        cardView.render(model: token.cardButtonViewModel)

        let isEnabled = viewModel.selectedId == viewModel.paymentMethods[indexPath.row].token ?? ""

        if showDeleteIcon {
            cardView.toggleError(isEnabled: showDeleteIcon)
        } else {
            cardView.hideIcon(isEnabled)
            cardView.toggleIcon()
        }

        cardView.hideBorder()

        cardView.addSeparatorLine()

        cell.addSubview(cardView)

        cardView.pin(to: cell)

        cell.backgroundColor = theme.colorTheme.main1

        return cell
    }
}

#endif
