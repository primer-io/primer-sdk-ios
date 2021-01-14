import UIKit

protocol DirectCheckoutViewDelegate: class {
    func cancel() -> Void
}

class DirectCheckoutView: UIView {
    
    let navBar = UINavigationBar()
    let tableView = UITableView()
    let cardButton = UIButton()
    let applePayButton = UIButton()
    let payPalButton = UIButton()
    
    let theme: PrimerTheme
    let amount: String
    
    weak var delegate: DirectCheckoutViewDelegate?
    
    init(frame: CGRect, theme: PrimerTheme, amount: String) {
        self.theme = theme
        self.amount = amount
        super.init(frame: frame)
        backgroundColor = theme.backgroundColor
        
        addSubview(navBar)
        addSubview(tableView)
        
        configureNavBar()
        configureTableView()
        
        anchorNavBar()
        anchorTableView()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func configureNavBar() {
        navBar.backgroundColor = theme.backgroundColor
        let navItem = UINavigationItem(title: "")
        let doneItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: #selector(cancel))
        doneItem.tintColor = .blue
        let title = UILabel()
        title.textColor = theme.fontColorTheme.total
        title.font = .boldSystemFont(ofSize: 32.0)
        title.text = amount
        let moneyItem = UIBarButtonItem(customView: title)
        navItem.leftBarButtonItem = doneItem
        navItem.rightBarButtonItem = moneyItem
        navBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navBar.shadowImage = UIImage()
        navBar.setItems([navItem], animated: false)
    }
    
    @objc private func cancel() { delegate?.cancel() }
    
    private func configureTableView() {
        tableView.layer.cornerRadius = 8.0
        tableView.backgroundColor = theme.backgroundColor
        tableView.rowHeight = 64
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.alwaysBounceVertical = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell3")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell4")
    }
    
    //
    
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
        tableView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12).isActive = true
    }
}
