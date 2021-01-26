import UIKit

protocol VaultCheckoutViewDelegate: class, UITableViewDelegate, UITableViewDataSource {
    var theme: PrimerTheme { get }
    func cancel()
    func openVault()
    func pay()
    func selectTokenForPayment(token: PaymentMethodToken)
}

protocol VaultCheckoutViewDataSource: class {
    var selectedSavedPaymentMethod: PaymentMethodToken? { get }
    var amount: String? { get }
}

class VaultCheckoutView: UIView, ReactiveView {
    let indicator = UIActivityIndicatorView()
    let navBar = UINavigationBar()
    let amountLabelView = UILabel()
    let savedCardTitleLabel = UILabel()
    var savedCardButton = CardButton()
    let otherMethodsTitleLabel = UILabel()
    let tableView = UITableView()
    let payButton = UIButton()
    let seeAllLinkLabel = UILabel()
    let fadeView = UIView()
    
    var selected = false
    
    weak var delegate: VaultCheckoutViewDelegate?
    weak var dataSource: VaultCheckoutViewDataSource?
    
    func render(isBusy: Bool = false) {
        addSubview(indicator)
        addSubview(navBar)
        addSubview(amountLabelView)
        addSubview(savedCardTitleLabel)
        addSubview(savedCardButton)
        addSubview(otherMethodsTitleLabel)
        addSubview(tableView)
        addSubview(seeAllLinkLabel)
        addSubview(fadeView)
        addSubview(payButton)
        
        subviews.forEach { $0.isHidden = isBusy }
        indicator.isHidden = !isBusy
        
        if (isBusy) {
            indicator.pin(to: self)
            indicator.startAnimating()
        } else {
            configureNavBar()
            configureTableView()
            configurePayButton()
            configureAmountLabelView()
            configureSavedCardTitleLabel()
            configureSavedCardButton()
            configureSeeAllLinkLabel()
            configureOtherMethodsTitleLabel()
            
            anchorNavBar()
            anchorTableView()
            anchorPayButton()
            indicator.stopAnimating()
        }
    }
    
    func reloadVaultDetails() {
        savedCardButton.reload(model: dataSource?.selectedSavedPaymentMethod?.cardButtonViewModel)
        payButton.isHidden = true
        savedCardButton.layoutIfNeeded()
    }
}

//MARK: Configuration
extension VaultCheckoutView {
    private func configureNavBar() {
//        guard let theme = delegate?.theme else { return }
//        navBar.backgroundColor = theme.backgroundColor
        let navItem = UINavigationItem()
//        let doneItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: #selector(cancel))
//        navItem.leftBarButtonItem = doneItem
        navBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navBar.shadowImage = UIImage()
        navBar.setItems([navItem], animated: false)
        navBar.topItem?.title = "Choose payment method".localized()
    }
    
    @objc private func cancel() {
        delegate?.cancel()
    }
    
    private func configureAmountLabelView() {
        amountLabelView.text = dataSource?.amount
        amountLabelView.font = .boldSystemFont(ofSize: 32)
        amountLabelView.translatesAutoresizingMaskIntoConstraints = false
        amountLabelView.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 6).isActive = true
        amountLabelView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
    }
    
    private func configureSavedCardTitleLabel() {
        savedCardTitleLabel.text = "SAVED CARD".localized()
        savedCardTitleLabel.textColor = .lightGray
        savedCardTitleLabel.font = .systemFont(ofSize: 12, weight: .light)
        savedCardTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        savedCardTitleLabel.topAnchor.constraint(equalTo: amountLabelView.bottomAnchor, constant: 12).isActive = true
        savedCardTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
    }
    
    private func configureSavedCardButton() {
        savedCardButton.translatesAutoresizingMaskIntoConstraints = false
        savedCardButton.topAnchor.constraint(equalTo: savedCardTitleLabel.bottomAnchor, constant: 12).isActive = true
        savedCardButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        savedCardButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
        savedCardButton.heightAnchor.constraint(equalToConstant: 64).isActive = true
        savedCardButton.addTarget(self, action: #selector(toggleSavedCardSelected), for: .touchUpInside)
        savedCardButton.render(model: dataSource?.selectedSavedPaymentMethod?.cardButtonViewModel)
    }
    
    @objc private func toggleSavedCardSelected() {
        print("toggle!")
        selected = !selected
        addFadeView(isEnabled: selected)
        payButton.isHidden = !selected
        savedCardButton.toggleBorder(isSelected: selected)
        savedCardButton.toggleIcon(isEnabled: !selected)
    }
    
    private func addFadeView(isEnabled: Bool) {
        let val: CGFloat = isEnabled ? 0.5 : 0.0
        fadeView.backgroundColor = UIColor.white.withAlphaComponent(val)
        fadeView.isUserInteractionEnabled = isEnabled
        fadeView.translatesAutoresizingMaskIntoConstraints = false
        fadeView.topAnchor.constraint(equalTo: savedCardButton.bottomAnchor).isActive = true
        fadeView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        fadeView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        fadeView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    private func configureSeeAllLinkLabel() {
        seeAllLinkLabel.text = "See All".localized()
        seeAllLinkLabel.font = .systemFont(ofSize: 14)
        seeAllLinkLabel.textColor = .systemBlue
        seeAllLinkLabel.translatesAutoresizingMaskIntoConstraints = false
        seeAllLinkLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        seeAllLinkLabel.topAnchor.constraint(equalTo: savedCardButton.bottomAnchor, constant: 12).isActive = true
        let tapRecogniser = UITapGestureRecognizer(target: self, action: #selector(openVault))
        seeAllLinkLabel.addGestureRecognizer(tapRecogniser)
        seeAllLinkLabel.isUserInteractionEnabled = true
    }
    
    @objc private func openVault() {
        delegate?.openVault()
    }
    
    private func configureOtherMethodsTitleLabel() {
        otherMethodsTitleLabel.text = "OTHER WAYS TO PAY".localized()
        otherMethodsTitleLabel.textColor = .lightGray
        otherMethodsTitleLabel.font = .systemFont(ofSize: 12, weight: .light)
        otherMethodsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        otherMethodsTitleLabel.topAnchor.constraint(equalTo: seeAllLinkLabel.bottomAnchor, constant: 24).isActive = true
        otherMethodsTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
    }
    
    private func configureTableView() {
        tableView.delegate = delegate
        tableView.dataSource = delegate
        tableView.layer.cornerRadius = 8.0
        tableView.backgroundColor = .white
        tableView.rowHeight = 56
        tableView.tableFooterView = UIView()
        tableView.alwaysBounceVertical = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell3")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell4")
    }
    
    func configurePayButton() {
        guard let theme = delegate?.theme else { return }
        payButton.layer.cornerRadius = 12
        payButton.setTitle(theme.content.vaultCheckout.payButtonText, for: .normal)
        payButton.setTitleColor(theme.fontColorTheme.payButton, for: .normal)
        payButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        payButton.backgroundColor = theme.buttonColorTheme.payButton
        payButton.addTarget(self, action: #selector(onTap), for: .touchUpInside)
        let imageView = UIImageView(image: ImageName.lock.image)
        payButton.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.centerYAnchor.constraint(equalTo: payButton.centerYAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: payButton.trailingAnchor, constant: -16).isActive = true
        payButton.isHidden = true //before it's toggled, hide
    }
    
    @objc private func onTap(sender: UIButton) {
        payButton.isEnabled = false
        print("paying!")
        payButton.showSpinner()
        delegate?.pay()
    }
}

//MARK: Anchoring
extension VaultCheckoutView {
    private func anchorNavBar() {
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.topAnchor.constraint(equalTo: topAnchor, constant: 6).isActive = true
        navBar.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    }
    
    private func anchorTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: otherMethodsTitleLabel.bottomAnchor, constant: 12).isActive = true
        tableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        tableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
        tableView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    private func anchorPayButton() {
        payButton.translatesAutoresizingMaskIntoConstraints = false
        payButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12).isActive = true
        payButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        payButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18).isActive = true
        payButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18).isActive = true
        payButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
}
