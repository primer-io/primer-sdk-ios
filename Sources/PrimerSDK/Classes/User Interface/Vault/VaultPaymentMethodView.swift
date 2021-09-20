#if canImport(UIKit)

import UIKit

internal protocol VaultPaymentMethodViewDelegate: UITableViewDelegate, UITableViewDataSource {
    func cancel()
    func edit()
    func showPayPal()
}

internal protocol ReactiveView: UIView {
    var indicator: UIActivityIndicatorView { get }
    func render(isBusy: Bool)
}

internal class VaultPaymentMethodView: PrimerView, ReactiveView {

    let indicator = UIActivityIndicatorView()
//    let navBar = UINavigationBar()
    let tableView = UITableView()

    weak var delegate: VaultPaymentMethodViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)

//        addSubview(navBar)
        addSubview(tableView)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func render(isBusy: Bool = false) {
//        configureNavBar()
        configureTableView()

        anchorNavBar()
        anchorTableView()
    }
}

// MARK: Configuration
internal extension VaultPaymentMethodView {
    private func configureNavBar() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
//        navBar.backgroundColor = theme.colorTheme.main1
        let navItem = UINavigationItem()
        let backItem = UIBarButtonItem()
        backItem.action = #selector(cancel)
        let backBtnImage = ImageName.back.image
        backItem.tintColor = theme.colorTheme.tint1
        backItem.image = backBtnImage
        let editItem = UIBarButtonItem()
        editItem.title = theme.content.vaultPaymentMethodView.editButtonText
        editItem.tintColor = theme.colorTheme.tint1
        editItem.action = #selector(edit)
        navItem.leftBarButtonItem = backItem
        navItem.rightBarButtonItem = editItem
//        navBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
//        navBar.shadowImage = UIImage()
//        navBar.setItems([navItem], animated: false)
//        navBar.topItem?.title = theme.content.vaultPaymentMethodView.mainTitleText.uppercased()
    }

    @objc private func cancel() { delegate?.cancel() }

    @objc private func edit() { delegate?.edit() }

    private func configureTableView() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        tableView.delegate = delegate
        tableView.dataSource = delegate
        tableView.layer.cornerRadius = 8.0
        tableView.backgroundColor = theme.colorTheme.main1
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        tableView.rowHeight = 64
        tableView.alwaysBounceVertical = false
    }

    @objc private func showCardForm() { }
}

// MARK: Anchoring
internal extension VaultPaymentMethodView {
    private func anchorNavBar() {
//        navBar.translatesAutoresizingMaskIntoConstraints = false
//        navBar.topAnchor.constraint(equalTo: topAnchor, constant: 6).isActive = true
//        navBar.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    }

    private func anchorTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: topAnchor, constant: 12).isActive = true
        tableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        tableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
        tableView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12).isActive = true
    }
}

#endif
