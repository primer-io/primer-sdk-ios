#if canImport(UIKit)

import UIKit

internal class VaultedPaymentInstrumentCell: UITableViewCell {
    
    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
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
        cardNetworkLabel.textColor = theme.colorTheme.text1
        
        cardholderNameLabel.text = paymentMethodToken.cardButtonViewModel?.cardholder
        cardholderNameLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        cardholderNameLabel.textColor = theme.colorTheme.text1
        
        last4DigitsLabel.text = paymentMethodToken.cardButtonViewModel?.last4
        last4DigitsLabel.textAlignment = .right
        last4DigitsLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        last4DigitsLabel.textColor = theme.colorTheme.text1
        
        expiryDateLabel.text = paymentMethodToken.cardButtonViewModel?.expiry
        expiryDateLabel.textAlignment = .right
        expiryDateLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        expiryDateLabel.textColor = theme.colorTheme.text1
        
        contentView.backgroundColor = theme.colorTheme.main1
    }

}

internal class VaultedPaymentInstrumentsViewController: PrimerViewController {
    
    private var rightBarButton: UIButton!
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

        rightBarButton = UIButton()
        rightBarButton.setTitle(theme.content.vaultPaymentMethodView.editButtonText, for: .normal)
        rightBarButton.setTitleColor(theme.colorTheme.main1, for: .normal)
        rightBarButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
        
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
        (parent as? PrimerContainerViewController)?.mockedNavigationBar.rightBarButton = rightBarButton
    }
    
    @objc
    func editButtonTapped(_ sender: UIButton) {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        isDeleting = !isDeleting
        rightBarButton.setTitle(isDeleting ? "Done" : theme.content.vaultPaymentMethodView.editButtonText, for: .normal)
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

#endif
