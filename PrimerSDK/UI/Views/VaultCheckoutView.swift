import UIKit

class VaultCheckoutView: UIView {
    
    let tableView = UITableView()
    let payButton = UIButton()
    let applePayButton = UIButton()
    
    // styling
    private let cornerRadius: CGFloat = 8.0
    private let bkgColor = UIColor(red: 246.0/255.0, green: 246.0/255.0, blue: 246.0/255.0, alpha: 1)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureTableView()
        configurePayButton()
        configureApplePayButton()
        anchorTableView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureTableView() {
        addSubview(tableView)
        tableView.layer.cornerRadius = 8.0
        tableView.backgroundColor = bkgColor
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
    
    //    payButton.setTitle("Pay $" + String(format: "%.2f", (Double(checkout.amount) / 100)), for: .normal)
    
    func configurePayButton() {
        addSubview(payButton)
        payButton.layer.cornerRadius = cornerRadius
        payButton.setTitleColor(.white, for: .normal)
        payButton.backgroundColor = .black
        payButton.translatesAutoresizingMaskIntoConstraints = false
        payButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12).isActive = true
        payButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        payButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        payButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
        payButton.heightAnchor.constraint(equalToConstant: 64).isActive = true
    }
    
    func configureApplePayButton() {
        addSubview(applePayButton)
        applePayButton.layer.cornerRadius = cornerRadius
        applePayButton.setTitle(" Pay", for: .normal)
        applePayButton.backgroundColor = .gray
        applePayButton.translatesAutoresizingMaskIntoConstraints = false
        applePayButton.bottomAnchor.constraint(equalTo: payButton.topAnchor, constant: -12).isActive = true
        applePayButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        applePayButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        applePayButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
        applePayButton.heightAnchor.constraint(equalToConstant: 64).isActive = true
    }
    
    private func anchorTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: topAnchor, constant: 12).isActive = true
        tableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        tableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
        tableView.bottomAnchor.constraint(equalTo: applePayButton.topAnchor, constant: -12).isActive = true
    }
    
}
