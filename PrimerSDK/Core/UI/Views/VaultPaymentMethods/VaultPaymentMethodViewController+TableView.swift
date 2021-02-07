import UIKit

extension VaultPaymentMethodViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        
        headerView.backgroundColor = UIColor.clear
        
        return headerView
    }
    
    @objc private func showCardForm(_ sender: UIButton) {
        router.show(.cardForm)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.row == viewModel.paymentMethods.count) {
            return
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if (!showDeleteIcon) {
            
            viewModel.selectedId = viewModel.paymentMethods[indexPath.row].token ?? ""

            tableView.reloadData()
            
        } else {
            
            guard let methodId = viewModel.paymentMethods[indexPath.row].token else { return }

            let alert = UIAlertController(
                title: "Confirmation",
                message: "Are you sure you want to delete this payment method?",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] action in
                self?.viewModel.deletePaymentMethod(with: methodId, and: { [weak self] error in
                    DispatchQueue.main.async { self?.subView.tableView.reloadData() }
                })
            }))

            present(alert, animated: true, completion: nil)
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }

    @objc private func deleteMethod(sender: UIButton) {
        guard let methodId = viewModel.paymentMethods[sender.tag].token else { return }
        viewModel.deletePaymentMethod(with: methodId, and: { [weak self] error in
            DispatchQueue.main.async { self?.subView.tableView.reloadData() }
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.paymentMethods.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        if (indexPath.row == viewModel.paymentMethods.count) {
            let addButton = UIButton()
            
            addButton.setTitle(Primer.theme.content.vaultPaymentMethodView.addButtonText, for: .normal)
            addButton.setTitleColor(Primer.theme.colorTheme.tint1, for: .normal)
            addButton.setTitleColor(Primer.theme.colorTheme.disabled1, for: .highlighted)
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
        
        if (showDeleteIcon) {
            cardView.toggleError(isEnabled: showDeleteIcon)
        } else {
            cardView.hideIcon(isEnabled)
            cardView.toggleIcon()
        }
        
        cardView.hideBorder()
        
        cardView.addSeparatorLine()
        
        cell.addSubview(cardView)
        
        cardView.pin(to: cell)
        
        cell.backgroundColor = Primer.theme.colorTheme.main1

        return cell
    }
}
