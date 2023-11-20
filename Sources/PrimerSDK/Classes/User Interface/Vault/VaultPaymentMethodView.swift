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
    let tableView = UITableView()

    weak var delegate: VaultPaymentMethodViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(tableView)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func render(isBusy: Bool = false) {
        configureTableView()
        anchorTableView()
    }
}

// MARK: Configuration
internal extension VaultPaymentMethodView {

    @objc private func cancel() { delegate?.cancel() }

    @objc private func edit() { delegate?.edit() }

    private func configureTableView() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()

        tableView.delegate = delegate
        tableView.dataSource = delegate
        tableView.layer.cornerRadius = 8.0
        tableView.backgroundColor = theme.view.backgroundColor
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        tableView.rowHeight = 64
        tableView.alwaysBounceVertical = false
    }

    @objc private func showCardForm() { }
}

// MARK: Anchoring
internal extension VaultPaymentMethodView {

    private func anchorTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: topAnchor, constant: 12).isActive = true
        tableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
        tableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
        tableView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12).isActive = true
    }
}
