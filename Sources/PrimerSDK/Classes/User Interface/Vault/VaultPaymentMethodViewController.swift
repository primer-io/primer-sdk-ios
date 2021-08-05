#if canImport(UIKit)

import UIKit

internal class VaultedPaymentInstrumentCell: UITableViewCell {
    
    private(set) var paymentMethodToken: PaymentMethodToken!
    var isDeleting: Bool = false {
        didSet {
            if isDeleting {
                checkmarmImageView.image = ImageName.delete.image
                checkmarmImageView.isHidden = false
            } else {
                checkmarmImageView.image = ImageName.check2.image
                checkmarmImageView.isHidden = !isEnabled
            }
        }
    }
    private var horizontalStackView = UIStackView()
    private var verticalLeftStackView = UIStackView()
    private var verticalRightStackView = UIStackView()
    private var cardNetworkImageView = UIImageView()
    private var cardNetworkLabel = UILabel()
    private var cardholderNameLabel = UILabel()
    private var last4DigitsLabel = UILabel()
    private var expiryDateLabel = UILabel()
    private var border = PrimerView()
    private var checkmarmImageView = UIImageView()
    
    
//    let cardView = CardButton()
    
    var isEnabled: Bool = false {
        didSet {
            checkmarmImageView.image = ImageName.check2.image
            checkmarmImageView.isHidden = !isEnabled
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        if horizontalStackView.superview == nil {
            contentView.addSubview(horizontalStackView)
            horizontalStackView.translatesAutoresizingMaskIntoConstraints = false
            horizontalStackView.pin(view: contentView, leading: 16, top: 8, trailing: -16, bottom: -8)
        }

        if cardNetworkImageView.superview == nil {
            horizontalStackView.addArrangedSubview(cardNetworkImageView)
            cardNetworkImageView.translatesAutoresizingMaskIntoConstraints = false
            cardNetworkImageView.widthAnchor.constraint(equalToConstant: 28).isActive = true
            cardNetworkImageView.heightAnchor.constraint(equalToConstant: 38).isActive = true
        }

        if verticalLeftStackView.superview == nil {
            horizontalStackView.addArrangedSubview(verticalLeftStackView)
        }
        
        if cardNetworkLabel.superview == nil {
            verticalLeftStackView.addArrangedSubview(cardNetworkLabel)
        }
        
        if cardholderNameLabel.superview == nil {
            verticalLeftStackView.addArrangedSubview(cardholderNameLabel)
        }

        if verticalRightStackView.superview == nil {
            horizontalStackView.addArrangedSubview(verticalRightStackView)
        }
        
        if last4DigitsLabel.superview == nil {
            verticalRightStackView.addArrangedSubview(last4DigitsLabel)
        }
        
        if expiryDateLabel.superview == nil {
            verticalRightStackView.addArrangedSubview(expiryDateLabel)
        }

        if checkmarmImageView.superview == nil {
            let checkmarkContainerView = UIView()
            checkmarkContainerView.translatesAutoresizingMaskIntoConstraints = false
            checkmarkContainerView.widthAnchor.constraint(equalToConstant: 14).isActive = true
            checkmarkContainerView.heightAnchor.constraint(equalToConstant: 22).isActive = true
            horizontalStackView.addArrangedSubview(checkmarkContainerView)

            checkmarkContainerView.addSubview(checkmarmImageView)
            checkmarmImageView.translatesAutoresizingMaskIntoConstraints = false
            checkmarmImageView.pin(view: checkmarkContainerView)
        }
    }
    
    func configure(paymentMethodToken: PaymentMethodToken, isDeleting: Bool) {
        self.paymentMethodToken = paymentMethodToken
        self.isDeleting = isDeleting
        
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        let viewModel: VaultPaymentMethodViewModelProtocol = DependencyContainer.resolve()
        isEnabled = viewModel.selectedId == paymentMethodToken.token ?? ""
        
        horizontalStackView.axis = .horizontal
        horizontalStackView.alignment = .fill
        horizontalStackView.spacing = 16
        
        verticalLeftStackView.axis = .vertical
        verticalLeftStackView.alignment = .fill
        verticalLeftStackView.distribution = .fillEqually
        verticalLeftStackView.spacing = 0
        
        verticalRightStackView.axis = .vertical
        verticalRightStackView.alignment = .fill
        verticalRightStackView.distribution = .fillEqually
        verticalRightStackView.spacing = 0
        
        cardNetworkImageView.image = paymentMethodToken.cardButtonViewModel?.imageName.image
        cardNetworkImageView.contentMode = .scaleAspectFit
        
        checkmarmImageView.image = isDeleting ? ImageName.delete.image?.withRenderingMode(.alwaysTemplate) : ImageName.check2.image?.withRenderingMode(.alwaysTemplate)
        checkmarmImageView.tintColor = theme.colorTheme.tint1
        checkmarmImageView.contentMode = .scaleAspectFit
        checkmarmImageView.isHidden = isDeleting ? false : !isEnabled
        
        cardNetworkLabel.text = paymentMethodToken.cardButtonViewModel?.network
        cardNetworkLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        cardNetworkLabel.textColor = .black
        
        cardholderNameLabel.text = paymentMethodToken.cardButtonViewModel?.cardholder
        cardholderNameLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        cardholderNameLabel.textColor = .black
        
        last4DigitsLabel.text = paymentMethodToken.cardButtonViewModel?.last4
        last4DigitsLabel.textAlignment = .right
        last4DigitsLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        last4DigitsLabel.textColor = .black
        
        expiryDateLabel.text = paymentMethodToken.cardButtonViewModel?.expiry
        expiryDateLabel.textAlignment = .right
        expiryDateLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        expiryDateLabel.textColor = .black
        
        contentView.backgroundColor = theme.colorTheme.main1
    }

}

internal class VaultedPaymentInstrumentsViewController: PrimerViewController {
    
    private var rightBarButton: UIBarButtonItem!
    private var isDeleting: Bool = false {
        didSet {
            for cell in tableView.visibleCells {
                (cell as? VaultedPaymentInstrumentCell)?.isDeleting = isDeleting
            }
        }
    }
    private var tableView = UITableView()
    
    weak var delegate: ReloadDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        title = theme.content.vaultPaymentMethodView.mainTitleText
        
        rightBarButton = UIBarButtonItem(title: "Edit", style: UIBarButtonItem.Style.plain, target: self, action: #selector(editButtonTapped))
        rightBarButton.tintColor = theme.colorTheme.main1
        rightBarButton.title = theme.content.vaultPaymentMethodView.editButtonText
        rightBarButton.tintColor = theme.colorTheme.tint1
        
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
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
        isDeleting = !isDeleting
        rightBarButton.title = isDeleting ? "Done" : "Edit"
    }
    
    private func deletePaymentMethod(_ paymentMethodToken: String) {
        let viewModel: VaultPaymentMethodViewModelProtocol = DependencyContainer.resolve()
        viewModel.deletePaymentMethod(with: paymentMethodToken, and: { [weak self] _ in
            DispatchQueue.main.async {
                self?.delegate?.reload()
                self?.tableView.reloadData()
                
                // Going back if no payment method remains
                if viewModel.paymentMethods.isEmpty {
                    Primer.shared.primerRootVC?.popViewController()
                }
            }
        })
    }
    
}

extension VaultedPaymentInstrumentsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64.0
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
        cell.configure(paymentMethodToken: paymentMethod, isDeleting: isDeleting)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewModel: VaultPaymentMethodViewModelProtocol = DependencyContainer.resolve()
        let paymentMethod = viewModel.paymentMethods[indexPath.row]
        
        if !isDeleting {
            viewModel.selectedId = paymentMethod.token ?? ""
            tableView.reloadData()
            // It will reload the payment instrument on the Universal Checkout view.
            delegate?.reload()
        } else {
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
                                    self?.deletePaymentMethod(paymentMethod.token ?? "")
                                }))

            alert.show()
        }
        
        tableView.reloadData()
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
            delegate?.reload()
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
            cardView.showCheckmarkIcon(isEnabled)
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
