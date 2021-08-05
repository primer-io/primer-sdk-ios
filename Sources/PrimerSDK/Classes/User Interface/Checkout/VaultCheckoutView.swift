#if canImport(UIKit)
import UIKit

internal protocol VaultCheckoutViewDelegate: class, UITableViewDelegate, UITableViewDataSource {
    func cancel()
    func openVault()
    func pay()
    func selectTokenForPayment(token: PaymentMethodToken)
}

internal protocol VaultCheckoutViewDataSource: class {
    var selectedSavedPaymentMethod: PaymentMethodToken? { get }
    var amount: String? { get }
}

internal class VaultCheckoutView: PrimerView, ReactiveView {

    let indicator = UIActivityIndicatorView()
    let navBar = UINavigationBar()
    let titleLabel = UILabel()
    let amountLabelView = UILabel()
    let savedCardTitleLabel = UILabel()
    var savedCardButtonView = CardButton()
    let otherMethodsTitleLabel = UILabel()
    let tableView = UITableView()
    let payButton = PrimerButton()
    let seeAllLinkLabel = UILabel()
    let fadeView = UIView()

    var selected = false

    let vaulted: Bool = Primer.shared.flow.internalSessionFlow.vaulted

    weak var delegate: VaultCheckoutViewDelegate?
    weak var dataSource: VaultCheckoutViewDataSource?

    weak var checkmarkViewHeightConstraint: NSLayoutConstraint?
    weak var topConstraint: NSLayoutConstraint?
    
    private var isShowingFirstVaultedPaymentMethod: Bool {
//        return false
        if Primer.shared.flow.internalSessionFlow.vaulted { return false }
        return (dataSource?.selectedSavedPaymentMethod?.cardButtonViewModel.exists == true)
    }
    
    private var isShowingAmount: Bool {
//        return false
        if Primer.shared.flow.internalSessionFlow.vaulted { return false }
        return dataSource?.amount != nil
    }

    func render(isBusy: Bool = false) {
        addSubview(indicator)
        addSubview(navBar)
        addSubview(titleLabel)
        addSubview(amountLabelView)
        addSubview(savedCardTitleLabel)
        addSubview(savedCardButtonView)
        addSubview(otherMethodsTitleLabel)
        addSubview(tableView)
        addSubview(seeAllLinkLabel)
        addSubview(fadeView)
        addSubview(payButton)

        subviews.forEach { $0.isHidden = isBusy }
        indicator.isHidden = !isBusy

        if isBusy {
            indicator.translatesAutoresizingMaskIntoConstraints = false
            indicator.topAnchor.constraint(equalTo: topAnchor).isActive = true
            indicator.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            indicator.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            indicator.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            
            indicator.startAnimating()
        } else {
            configureNavBar()
            configureTitleLabel()
            configureTableView()
            configurePayButton()
            configureAmountLabelView()
            configureSavedCardTitleLabel()
            configureSavedCardButton()
            configureSeeAllLinkLabel()
            configureOtherMethodsTitleLabel()

            addFadeView()

            anchorNavBar()
            anchorTableView()
            anchorPayButton()
            indicator.stopAnimating()
        }
        
        navBar.isHidden = true
//        amountLabelView.isHidden = !isShowingAmount
//        savedCardTitleLabel.isHidden = !isShowingFirstVaultedPaymentMethod
//        savedCardButton.isHidden = !isShowingFirstVaultedPaymentMethod
//        seeAllLinkLabel.isHidden = !isShowingFirstVaultedPaymentMethod
//        otherMethodsTitleLabel.isHidden = false
        layoutIfNeeded()
    }

    func reloadVaultDetails() {
        if !Primer.shared.flow.internalSessionFlow.vaulted {
            configureSavedCardTitleLabel()
            configureSavedCardButton()
            configureSeeAllLinkLabel()
            configureOtherMethodsTitleLabel()
            payButton.isHidden = true
            savedCardButtonView.layoutIfNeeded()
        }
    }

    // MARK: Configuration
    
    private func configureNavBar() {
        //        guard let theme = delegate?.theme else { return }
        //        navBar.backgroundColor = theme.backgroundColor
        let navItem = UINavigationItem()
        //        let doneItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: #selector(cancel))
        //        navItem.leftBarButtonItem = doneItem
        navBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navBar.shadowImage = UIImage()
        let titleItem = UINavigationItem(title: "")
        navBar.setItems([navItem, titleItem], animated: false)
        
        
        navBar.topItem?.title = Primer.shared.flow.internalSessionFlow.vaulted ?
            NSLocalizedString("primer-vault-nav-bar-title",
                              tableName: nil,
                              bundle: Bundle.primerResources,
                              value: "Add payment method",
                              comment: "Add payment method - Vault Navigation Bar Title")
            :
            NSLocalizedString("primer-checkout-nav-bar-title",
                              tableName: nil,
                              bundle: Bundle.primerResources,
                              value: "Choose payment method",
                              comment: "Choose payment method - Checkout Navigation Bar Title")
    }

    @objc private func cancel() {
        delegate?.cancel()
    }
    
    private func configureTitleLabel() {
        titleLabel.font = .boldSystemFont(ofSize: 17)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: -28).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20).isActive = true
        titleLabel.textAlignment = .center
        titleLabel.text = Primer.shared.flow.internalSessionFlow.vaulted ?
            NSLocalizedString("primer-vault-nav-bar-title",
                              tableName: nil,
                              bundle: Bundle.primerResources,
                              value: "Add payment method",
                              comment: "Add payment method - Vault Navigation Bar Title")
            :
            NSLocalizedString("primer-checkout-nav-bar-title",
                              tableName: nil,
                              bundle: Bundle.primerResources,
                              value: "Choose payment method",
                              comment: "Choose payment method - Checkout Navigation Bar Title")
    }

    private func configureAmountLabelView() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        if isShowingAmount {
            amountLabelView.text = dataSource?.amount
            amountLabelView.font = .boldSystemFont(ofSize: 32)
            amountLabelView.translatesAutoresizingMaskIntoConstraints = false
            amountLabelView.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 6).isActive = true
            amountLabelView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: theme.layout.safeMargin).isActive = true
        } else {
            amountLabelView.isHidden = true
        }
    }

    private func configureSavedCardTitleLabel() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        savedCardTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        if isShowingFirstVaultedPaymentMethod {
            savedCardTitleLabel.text = NSLocalizedString("primer-vault-checkout-payment-method-title",
                                                         tableName: nil,
                                                         bundle: Bundle.primerResources,
                                                         value: "SAVED PAYMENT METHOD",
                                                         comment: "SAVED PAYMENT METHOD - Vault Checkout Card Title")

            savedCardTitleLabel.textColor = theme.colorTheme.secondaryText1
            savedCardTitleLabel.font = .systemFont(ofSize: 12, weight: .light)

            savedCardTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: theme.layout.safeMargin).isActive = true
            
            if isShowingAmount {
                savedCardTitleLabel.topAnchor.constraint(equalTo: amountLabelView.bottomAnchor, constant: 12).isActive = true
            } else {
                savedCardTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12).isActive = true
            }
        } else {
            savedCardTitleLabel.isHidden = true
        }
    }

    private func configureSavedCardButton() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        savedCardButtonView.translatesAutoresizingMaskIntoConstraints = false
        
        if isShowingFirstVaultedPaymentMethod, let buttonViewModel = dataSource?.selectedSavedPaymentMethod?.cardButtonViewModel {
            savedCardButtonView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: theme.layout.safeMargin).isActive = true
            savedCardButtonView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -theme.layout.safeMargin).isActive = true
            
            topConstraint = savedCardButtonView.topAnchor.constraint(equalTo: savedCardTitleLabel.bottomAnchor, constant: 12)
            checkmarkViewHeightConstraint = savedCardButtonView.heightAnchor.constraint(equalToConstant: 64)
            checkmarkViewHeightConstraint?.isActive = true
            topConstraint?.isActive = true
            
            savedCardButtonView.addTarget(self, action: #selector(toggleSavedCardSelected), for: .touchUpInside)
            savedCardButtonView.subviews.forEach { $0.removeFromSuperview() }
            savedCardButtonView.render(model: buttonViewModel, showIcon: false)
            
        } else {
            savedCardButtonView.isHidden = true
        }
    }

    @objc private func toggleSavedCardSelected() {
        UIView.animate(withDuration: 0.25, animations: {[weak self] in
            guard let strongSelf = self else { return }
            strongSelf.selected = !strongSelf.selected
            strongSelf.toggleFadeView(isEnabled: strongSelf.selected)
            strongSelf.payButton.isHidden = !strongSelf.selected
            strongSelf.savedCardButtonView.toggleBorder(isSelected: strongSelf.selected)
            //            strongSelf.savedCardButton.toggleIcon(isEnabled: !strongSelf.selected)
            strongSelf.layoutIfNeeded()
        })
    }

    private func toggleFadeView(isEnabled: Bool) {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        let val: CGFloat = isEnabled ? 0.5 : 0.0
        fadeView.backgroundColor = theme.colorTheme.main1.withAlphaComponent(val)
        fadeView.isUserInteractionEnabled = isEnabled
    }

    private func addFadeView() {
        fadeView.isUserInteractionEnabled = false
        fadeView.translatesAutoresizingMaskIntoConstraints = false
        fadeView.topAnchor.constraint(equalTo: savedCardButtonView.bottomAnchor).isActive = true
        fadeView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        fadeView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        fadeView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height).isActive = true
    }

    private func configureSeeAllLinkLabel() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        seeAllLinkLabel.translatesAutoresizingMaskIntoConstraints = false
        if isShowingFirstVaultedPaymentMethod {
            seeAllLinkLabel.text = NSLocalizedString("primer-vault-checkout-see-all",
                                    tableName: nil,
                                    bundle: Bundle.primerResources,
                                    value: "See All",
                                    comment: "See All - Vault Checkout See All Button")
            seeAllLinkLabel.font = .systemFont(ofSize: 14)
            seeAllLinkLabel.textColor = theme.colorTheme.text3
            let tapRecogniser = UITapGestureRecognizer(target: self, action: #selector(openVault))
            seeAllLinkLabel.addGestureRecognizer(tapRecogniser)
            seeAllLinkLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            seeAllLinkLabel.topAnchor.constraint(equalTo: savedCardButtonView.bottomAnchor, constant: 12).isActive = true
            seeAllLinkLabel.isUserInteractionEnabled = true

        } else {
            seeAllLinkLabel.isHidden = true
        }

    }

    @objc private func openVault() {
        delegate?.openVault()
    }

    private func configureOtherMethodsTitleLabel() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        otherMethodsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        otherMethodsTitleLabel.text = NSLocalizedString("primer-vault-payment-method-available-payment-methods",
                                tableName: nil,
                                bundle: Bundle.primerResources,
                                value: "Available payment methods",
                                comment: "Available payment methods - Vault Checkout 'Available payment methods' Title").uppercased()
        otherMethodsTitleLabel.textColor = theme.colorTheme.secondaryText1
        otherMethodsTitleLabel.font = .systemFont(ofSize: 12, weight: .light)
        
        if isShowingFirstVaultedPaymentMethod {
            otherMethodsTitleLabel.topAnchor.constraint(equalTo: seeAllLinkLabel.bottomAnchor, constant: 24).isActive = true
        } else if isShowingAmount {
            otherMethodsTitleLabel.topAnchor.constraint(equalTo: amountLabelView.bottomAnchor, constant: 24).isActive = true
        } else {
            otherMethodsTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24).isActive = true
        }

        otherMethodsTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: theme.layout.safeMargin).isActive = true
    }

    private func configureTableView() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        tableView.accessibilityIdentifier = "payment_methods_table_view"
        tableView.delegate = delegate
        tableView.dataSource = delegate
        tableView.layer.cornerRadius = 8.0
        tableView.backgroundColor = theme.colorTheme.main1
        tableView.rowHeight = 46
        tableView.tableFooterView = UIView()
        tableView.alwaysBounceVertical = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell3")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell4")
    }

    func configurePayButton() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        payButton.layer.cornerRadius = 12
        payButton.setTitle(theme.content.vaultCheckout.payButtonText, for: .normal)
        payButton.setTitleColor(theme.colorTheme.text2, for: .normal)
        payButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        payButton.backgroundColor = theme.colorTheme.tint1
        payButton.addTarget(self, action: #selector(onTap), for: .touchUpInside)
        let imageView = UIImageView(image: ImageName.lock.image)
        payButton.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.centerYAnchor.constraint(equalTo: payButton.centerYAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: payButton.trailingAnchor, constant: -16).isActive = true
        payButton.isHidden = true // before it's toggled, hide
    }

    @objc private func onTap(sender: UIButton) {
        // FIXME: Why would you have a function that takes a UIButton as input, but then perform actions on payButton?
        payButton.isEnabled = false
        log(logLevel: .verbose, title: nil, message: "Paying", prefix: nil, suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)
        payButton.showSpinner(true)
        delegate?.pay()
    }
}

// MARK: Anchoring
internal extension VaultCheckoutView {
    private func anchorNavBar() {
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.topAnchor.constraint(equalTo: topAnchor, constant: 6).isActive = true
        navBar.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    }

    private func anchorTableView() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: otherMethodsTitleLabel.bottomAnchor, constant: 0).isActive = true
        
        tableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: theme.layout.safeMargin).isActive = true
        tableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -theme.layout.safeMargin).isActive = true
        
        let vaultViewModel: VaultCheckoutViewModelProtocol = DependencyContainer.resolve()
        tableView.heightAnchor.constraint(equalToConstant: 400).isActive = true
    }

    private func anchorPayButton() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        payButton.translatesAutoresizingMaskIntoConstraints = false
        payButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -30).isActive = true
        payButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        payButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: theme.layout.safeMargin).isActive = true
        payButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -theme.layout.safeMargin).isActive = true
        payButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
}

#endif
