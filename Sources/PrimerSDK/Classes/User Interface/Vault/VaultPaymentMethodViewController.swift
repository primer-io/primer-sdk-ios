#if canImport(UIKit)

import UIKit

internal class VaultedPaymentInstrumentCell: UITableViewCell {
    
    let cardView = CardButton()
    var isDeleting: Bool = false {
        didSet {
            if isDeleting {
                cardView.showDeleteIcon(isDeleting)
            } else {
                cardView.hideIcon(isEnabled)
                cardView.toggleIcon()
            }
        }
    }
    var isEnabled: Bool = false

    
    func configure(paymentMethodToken: PaymentMethodToken) {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        let viewModel: VaultPaymentMethodViewModelProtocol = DependencyContainer.resolve()
        
        cardView.isUserInteractionEnabled = false
        cardView.render(model: paymentMethodToken.cardButtonViewModel)
        isEnabled = viewModel.selectedId == paymentMethodToken.token ?? ""

        cardView.hideBorder()
        cardView.addSeparatorLine()
        addSubview(cardView)
        
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        cardView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        cardView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        cardView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        backgroundColor = theme.colorTheme.main1
    }

    
}

internal class VaultedPaymentInstrumentsViewController: PrimerViewController {
    
    private var rightBarButton: UIBarButtonItem!
    private var isDeleting: Bool = false
    private var tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Primer.shared.flow.internalSessionFlow.vaulted {
            title = NSLocalizedString("primer-vault-payment-method-available-payment-methods",
                                      tableName: nil,
                                      bundle: Bundle.primerResources,
                                      value: "Available payment methods",
                                      comment: "Available payment methods - Vault Payment Method (Main title text)")
        } else {
            title = NSLocalizedString("primer-vault-payment-method-saved-payment-methods",
                                      tableName: nil,
                                      bundle: Bundle.primerResources,
                                      value: "Saved payment methods",
                                      comment: "Saved payment methods - Vault Payment Method (Main title text)")
        }

        
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        rightBarButton = UIBarButtonItem(title: "Edit", style: UIBarButtonItem.Style.plain, target: self, action: #selector(editButtonTapped))
        rightBarButton.tintColor = theme.colorTheme.main1
        
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.pin(view: view)
        tableView.accessibilityIdentifier = "payment_methods_table_view"
        tableView.backgroundColor = theme.colorTheme.main1
        tableView.rowHeight = 46
//        tableView.tableFooterView = UIView()
        tableView.alwaysBounceVertical = false
        tableView.register(VaultedPaymentInstrumentCell.self, forCellReuseIdentifier: "VaultedPaymentInstrumentCell")
        
        let viewModel: VaultPaymentMethodViewModelProtocol = DependencyContainer.resolve()
        viewModel.reloadVault { [weak self] _ in
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (parent as? PrimerContainerViewController)?.navigationItem.rightBarButtonItem = rightBarButton
    }
    
    @objc
    func editButtonTapped(_ sender: UIButton) {
        
    }
    
}

extension VaultedPaymentInstrumentsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let viewModel: VaultPaymentMethodViewModelProtocol = DependencyContainer.resolve()
        // That's actually payment instruments
        return viewModel.paymentMethods.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel: VaultPaymentMethodViewModelProtocol = DependencyContainer.resolve()
        let paymentMethod = viewModel.paymentMethods[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "VaultedPaymentInstrumentCell", for: indexPath) as! VaultedPaymentInstrumentCell
        cell.configure(paymentMethodToken: paymentMethod)
        return cell
    }
    
}

internal class VaultPaymentMethodViewController: PrimerViewController {
    
    var showDeleteIcon = false
    var subView: VaultPaymentMethodView = VaultPaymentMethodView()
    weak var delegate: ReloadDelegate?

    deinit {
        log(logLevel: .debug, message: "🧨 destroyed: \(self.self)")
    }

    override func viewDidLoad() {
        view.addSubview(subView)
        navigationController?.setNavigationBarHidden(true, animated: false)
        subView.delegate = self
        subView.pin(to: view)
        subView.render()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = NSLocalizedString("primer-vault-nav-bar-title",
                                  tableName: nil,
                                  bundle: Bundle.primerResources,
                                  value: "Add payment method",
                                  comment: "Add payment method - Vault Navigation Bar Title")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        title = NSLocalizedString("primer-vault-nav-bar-title",
                                  tableName: nil,
                                  bundle: Bundle.primerResources,
                                  value: "Add payment method",
                                  comment: "Add payment method - Vault Navigation Bar Title")
    }

    // FIXME: Do not handle logic based on UI events.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.reload()
    }
    
    @objc private func showCardForm(_ sender: UIButton) {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        let router: RouterDelegate = DependencyContainer.resolve()
        router.show(.form(type: .cardForm(theme: theme)))
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
    
}

extension VaultPaymentMethodViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()

        headerView.backgroundColor = UIColor.clear

        return headerView
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
        
        delegate?.reload()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
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
        cardView.isUserInteractionEnabled = false

        cardView.render(model: token.cardButtonViewModel)

        let isEnabled = viewModel.selectedId == viewModel.paymentMethods[indexPath.row].token ?? ""

        if showDeleteIcon {
            cardView.showDeleteIcon(showDeleteIcon)
        } else {
            cardView.hideIcon(isEnabled)
            cardView.toggleIcon()
        }

        cardView.hideBorder()

        cardView.addSeparatorLine()

        cell.addSubview(cardView)

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.topAnchor.constraint(equalTo: cell.topAnchor).isActive = true
        cardView.leadingAnchor.constraint(equalTo: cell.leadingAnchor).isActive = true
        cardView.trailingAnchor.constraint(equalTo: cell.trailingAnchor).isActive = true
        cardView.bottomAnchor.constraint(equalTo: cell.bottomAnchor).isActive = true

        cell.backgroundColor = theme.colorTheme.main1

        return cell
    }
}

extension VaultPaymentMethodViewController: VaultPaymentMethodViewDelegate {

    func edit() {
        showDeleteIcon = !showDeleteIcon
        subView.tableView.reloadData()
    }

    func cancel() {
        let router: RouterDelegate = DependencyContainer.resolve()
        router.pop()
    }

    func showPayPal() {
        let router: RouterDelegate = DependencyContainer.resolve()
        router.show(.oAuth(host: .paypal))
    }
}

#endif
