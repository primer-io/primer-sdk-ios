import UIKit

protocol VaultPaymentMethodViewDelegate: class, UITableViewDelegate, UITableViewDataSource {
    func cancel()
    func edit()
    func showPayPal()
}

protocol ReactiveView: UIView {
    var indicator: UIActivityIndicatorView { get }
    func render(isBusy: Bool)
}

class VaultPaymentMethodView: UIView, ReactiveView {
    let indicator = UIActivityIndicatorView()
    let navBar = UINavigationBar()
    let tableView = UITableView()
    let backButton = UIButton()
    let mainTitle = UILabel()
    let editButton = UIButton()
    let addButton = UIButton()
    let payPalButton = UIButton()
    
    weak var delegate: VaultPaymentMethodViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(navBar)
        addSubview(tableView)
//        addSubview(addButton)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func render(isBusy: Bool = false) {
        configureNavBar()
        configureTableView()
//        configureAddButton()
        
        anchorNavBar()
        anchorTableView()
//        anchorAddButton()
    }
}

//MARK: Configuration
extension VaultPaymentMethodView {
    private func configureNavBar() {
        navBar.backgroundColor = Primer.theme.colorTheme.main1
        let navItem = UINavigationItem()
        let backItem = UIBarButtonItem()
        backItem.action = #selector(cancel)
        let backBtnImage = ImageName.back.image
        backItem.tintColor = Primer.theme.colorTheme.tint1
        backItem.image = backBtnImage
        let editItem = UIBarButtonItem()
        editItem.title = Primer.theme.content.vaultPaymentMethodView.editButtonText
        editItem.tintColor = Primer.theme.colorTheme.tint1
        editItem.action = #selector(edit)
        navItem.leftBarButtonItem = backItem
        navItem.rightBarButtonItem = editItem
        navBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navBar.shadowImage = UIImage()
        navBar.setItems([navItem], animated: false)
        navBar.topItem?.title = Primer.theme.content.vaultPaymentMethodView.mainTitleText
    }
    
    @objc private func cancel() { delegate?.cancel() }
    @objc private func edit() { delegate?.edit() }
    
    private func configureTableView() {
        tableView.delegate = delegate
        tableView.dataSource = delegate
        tableView.layer.cornerRadius = 8.0
        tableView.backgroundColor = Primer.theme.colorTheme.main1
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        tableView.rowHeight = 64
        tableView.alwaysBounceVertical = false
    }
    
    private func configureAddButton() {
        addButton.setTitle(Primer.theme.content.vaultPaymentMethodView.addButtonText, for: .normal)
        addButton.setTitleColor(Primer.theme.colorTheme.tint1, for: .normal)
        addButton.setTitleColor(Primer.theme.colorTheme.disabled1, for: .highlighted)
        addButton.contentHorizontalAlignment = .left
        addButton.addTarget(self, action: #selector(showCardForm), for: .touchUpInside)
    }
    
    @objc private func showCardForm() { }
    
    private func configurePayPalButton() {
        payPalButton.setTitle("PayPal", for: .normal)
        payPalButton.setTitleColor(Primer.theme.colorTheme.text1, for: .normal)
        payPalButton.setTitleColor(Primer.theme.colorTheme.disabled1, for: .highlighted)
        payPalButton.backgroundColor = Primer.theme.colorTheme.main2
        payPalButton.addTarget(self, action: #selector(showPayPal), for: .touchUpInside)
    }
    
    @objc private func showPayPal() { delegate?.showPayPal() }
}

//MARK: Anchoring
extension VaultPaymentMethodView {
    private func anchorNavBar() {
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.topAnchor.constraint(equalTo: topAnchor, constant: 6).isActive = true
        navBar.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    }
    
    private func setBackButtonContraints() {
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.topAnchor.constraint(equalTo: topAnchor, constant: 24).isActive = true
        backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Primer.theme.layout.safeMargin).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 24).isActive = true
    }
    
    private func setMainTitleConstraints() {
        mainTitle.translatesAutoresizingMaskIntoConstraints = false
        mainTitle.topAnchor.constraint(equalTo: topAnchor, constant: 24).isActive = true
        mainTitle.heightAnchor.constraint(equalToConstant: 24).isActive = true
        mainTitle.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    }
    
    private func setEditButtonConstraints() {
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.topAnchor.constraint(equalTo: topAnchor, constant: 24).isActive = true
        editButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Primer.theme.layout.safeMargin).isActive = true
        editButton.heightAnchor.constraint(equalToConstant: Primer.theme.layout.safeMargin).isActive = true
        editButton.widthAnchor.constraint(equalToConstant: editButton.intrinsicContentSize.width).isActive = true
    }
    
    private func anchorTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 12).isActive = true
        tableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        tableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
        tableView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height).isActive = true
    }
    
    private func anchorAddButton() {
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -30).isActive = true
        addButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Primer.theme.layout.safeMargin).isActive = true
        addButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Primer.theme.layout.safeMargin).isActive = true
    }
    
    private func anchorPayPalButton() {
        payPalButton.translatesAutoresizingMaskIntoConstraints = false
        payPalButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18).isActive = true
        payPalButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Primer.theme.layout.safeMargin).isActive = true
        payPalButton.widthAnchor.constraint(equalToConstant: payPalButton.intrinsicContentSize.width).isActive = true
        payPalButton.heightAnchor.constraint(equalToConstant: payPalButton.intrinsicContentSize.height - 160).isActive = true
    }
}
