import UIKit

extension VaultPaymentMethodViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.paymentMethods.count
    }
    
    // Make the background color show through
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = PaymentMethodTableViewCell(
//            style: .default,
//            reuseIdentifier: "paymentMethodCell",
//            index: indexPath.section,
//            paymentMethods: viewModel.paymentMethods,
//            isSelected: viewModel.selectedId == viewModel.paymentMethods[indexPath.section].token,
//            showDeleteIcon: showDeleteIcon
//        )
//        cell.deleteButton.addTarget(self, action: #selector(deleteMethod), for: .touchUpInside)
        let token = viewModel.paymentMethods[indexPath.section]
        let cell = PaymentMethodTableViewCell(style: .default, reuseIdentifier: "paymentMethodCell", paymentMethod: token)
        let isEnabled = viewModel.selectedId == viewModel.paymentMethods[indexPath.section].token ?? ""
        print("isEnabled:", isEnabled)
        
        if (showDeleteIcon) {
            cell.cardView.toggleError(isEnabled: showDeleteIcon)
        } else {
            cell.cardView.toggleBorder(isSelected: isEnabled)
            cell.cardView.toggleIcon(isEnabled: !isEnabled)
        }
        
       
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if (!showDeleteIcon) {
            viewModel.selectedId = viewModel.paymentMethods[indexPath.section].token ?? ""
            tableView.reloadData()
        } else {
            guard let methodId = viewModel.paymentMethods[indexPath.section].token else { return }
            
            //
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
    
//    @objc private func deleteMethod(sender: UIButton) {
//        guard let methodId = viewModel.paymentMethods[sender.tag].token else { return }
//        viewModel.deletePaymentMethod(with: methodId, and: { [weak self] error in
//            DispatchQueue.main.async { self?.subView.tableView.reloadData() }
//        })
//    }
}

class PaymentMethodTableViewCell: UITableViewCell {
    
    let cardView = CardButton()
    var deleteButton = UIButton(type: .system)
    private let paymentMethod: PaymentMethodToken
    
    init(
        style: UITableViewCell.CellStyle,
        reuseIdentifier: String?,
        paymentMethod: PaymentMethodToken
    ) {
        
        self.paymentMethod = paymentMethod
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        cardView.render(model: paymentMethod.cardButtonViewModel)
        addSubview(cardView)
        cardView.pin(to: self)
//        self.layer.borderWidth = 1
//        self.layer.borderColor = UIColor.black.cgColor
//        self.layer.cornerRadius = 10
//        textLabel?.text = paymentMethod.description
//
//        if (showDeleteIcon) {
//            accessoryType = .none
//            if #available(iOS 13.0, *) {
//                deleteButton.setImage(ImageName.delete.image, for: .normal)
//            } else {
//                deleteButton.setImage(ImageName.delete.image, for: .normal)
//            }
//            deleteButton.tintColor = .red
//            deleteButton.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
//            deleteButton.tag = index
//
//            accessoryView = deleteButton
//        } else {
//            accessoryType = isSelected ? .checkmark : .none
//        }
//
//        separatorInset = .zero
//
//        if (index == paymentMethods.count - 1) {
//            separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
//        }
                
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
