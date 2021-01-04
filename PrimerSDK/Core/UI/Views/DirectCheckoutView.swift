import UIKit

class DirectCheckoutView: UIView {
    
    let tableView = UITableView()
    let title = UILabel()
    let cardButton = UIButton()
    let applePayButton = UIButton()
    let payPalButton = UIButton()
    
    let theme: PrimerTheme
    
    init(
        frame: CGRect,
        theme: PrimerTheme
    ) {
        self.theme = theme
        
        super.init(frame: frame)
        
        backgroundColor = theme.backgroundColor
        configureTitle()
        configureTableView()
        setTitleConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureTitle() {
        addSubview(title)
        title.textColor = theme.fontColorTheme.total
        title.font = .boldSystemFont(ofSize: 32.0)
    }
    
    private func configureTableView() {
        addSubview(tableView)
        tableView.layer.cornerRadius = 8.0
        tableView.backgroundColor = theme.backgroundColor
        tableView.rowHeight = 64
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.alwaysBounceVertical = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell3")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell4")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 12).isActive = true
        tableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        tableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
        tableView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12).isActive = true
    }
    
    func setTableViewDelegates(_ delegateDataSource: (UITableViewDelegate & UITableViewDataSource)) {
        tableView.delegate = delegateDataSource
        tableView.dataSource = delegateDataSource
    }
    
    func configureButton(_ btn: UIButton) {
        addSubview(btn)
        btn.backgroundColor = .gray
        btn.setTitle("pay", for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 24.0)
        btn.tintColor = .white
        btn.layer.cornerRadius = 8
    }
    
    private func setButtonTitles() {
        cardButton.setTitle("Pay by card", for: .normal)
        applePayButton.setTitle("Apple pay", for: .normal)
        payPalButton.setTitle("PayPal", for: .normal)
    }
    
    private func setButtonColors() {
        cardButton.backgroundColor = .gray
        applePayButton.backgroundColor = .black
        payPalButton.backgroundColor = .systemBlue
    }
    
    func setTitleConstraints() {
        title.translatesAutoresizingMaskIntoConstraints = false
        title.topAnchor.constraint(equalTo: topAnchor, constant: 12).isActive = true
        title.heightAnchor.constraint(equalToConstant: 56).isActive = true
        title.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -24).isActive = true
    }
    
    func setButtonConstraints(_ btn: UIButton, top:  NSLayoutYAxisAnchor) {
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.topAnchor.constraint(equalTo: top, constant: 12).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 56).isActive = true
        btn.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 24).isActive = true
        btn.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -24).isActive = true
    }
    
}
