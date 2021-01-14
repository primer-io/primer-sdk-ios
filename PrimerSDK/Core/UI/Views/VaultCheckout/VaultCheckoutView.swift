import UIKit

protocol VaultCheckoutViewDelegate: class {
    func cancel()
    func pay()
}

class VaultCheckoutView: UIView {
    
    let navBar = UINavigationBar()
    let tableView = UITableView()
    let payButton = UIButton()
    
    let theme: PrimerTheme
    
    weak var delegate: VaultCheckoutViewDelegate?
    
    init(frame: CGRect, theme: PrimerTheme, delegate: VaultCheckoutViewDelegate?) {
        self.theme = theme
        self.delegate = delegate
        super.init(frame: frame)
        
        backgroundColor = theme.backgroundColor
        
        addSubview(navBar)
        addSubview(tableView)
        addSubview(payButton)
        
        configureNavBar()
        configureTableView()
        configurePayButton()
        
        anchorNavBar()
        anchorTableView()
        anchorPayButton()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func configureNavBar() {
        navBar.backgroundColor = theme.backgroundColor
        let navItem = UINavigationItem(title: "")
        let doneItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: #selector(cancel))
        navItem.leftBarButtonItem = doneItem
        navBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navBar.shadowImage = UIImage()
        navBar.setItems([navItem], animated: false)
    }
    
    @objc private func cancel() { delegate?.cancel() }
    
    private func configureTableView() {
        tableView.backgroundColor = theme.backgroundColor
        tableView.layer.cornerRadius = 8.0
        tableView.backgroundColor = theme.backgroundColor
        tableView.rowHeight = 64
        tableView.tableFooterView = UIView()
        tableView.alwaysBounceVertical = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell3")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell4")
    }
    
    func setTableViewDelegates(_ delegateDataSource: (UITableViewDelegate & UITableViewDataSource)) {
        tableView.delegate = delegateDataSource
        tableView.dataSource = delegateDataSource
    }
    
    func configurePayButton() {
        payButton.layer.cornerRadius = theme.cornerRadiusTheme.buttons
        payButton.setTitle(theme.content.vaultCheckout.payButtonText, for: .normal)
        payButton.setTitleColor(theme.fontColorTheme.payButton, for: .normal)
        payButton.backgroundColor = theme.buttonColorTheme.payButton
        payButton.addTarget(self, action: #selector(onTap), for: .touchUpInside)
//        payButton.addTarget(self, action: #selector(onTap), for: .touchUpOutside)
//        payButton.addTarget(self, action: #selector(onTap2), for: .touchDown)
    }
    
    @objc private func onTap(sender: UIButton) {
        delegate?.pay()
    }
//    @objc private func onTap2(sender: UIButton) {
//        payButton.backgroundColor = .lightGray
//    }
    
    private func anchorNavBar() {
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.topAnchor.constraint(equalTo: topAnchor, constant: 6).isActive = true
        navBar.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    }
    
    private func anchorTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 12).isActive = true
        tableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        tableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
        tableView.bottomAnchor.constraint(equalTo: payButton.topAnchor, constant: -12).isActive = true
    }
    
    private func anchorPayButton() {
        payButton.translatesAutoresizingMaskIntoConstraints = false
        payButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12).isActive = true
        payButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        payButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        payButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
        payButton.heightAnchor.constraint(equalToConstant: 64).isActive = true
    }
    
}
