import UIKit

internal class VaultedPaymentInstrumentCell: UITableViewCell {

    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    private(set) var paymentMethod: PrimerPaymentMethodTokenData!
    var isDeleting: Bool = false {
        didSet {
            if isDeleting {
                checkmarkImageView.image = ImageName.delete.image
                checkmarkImageView.isHidden = false
            } else {
                checkmarkImageView.image = ImageName.check2.image
                checkmarkImageView.isHidden = !isEnabled
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
    private var checkmarkImageView = UIImageView()

    var isEnabled: Bool = false {
        didSet {
            checkmarkImageView.image = ImageName.check2.image
            checkmarkImageView.isHidden = !isEnabled
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

        if checkmarkImageView.superview == nil {
            let checkmarkContainerView = UIView()
            checkmarkContainerView.translatesAutoresizingMaskIntoConstraints = false
            checkmarkContainerView.widthAnchor.constraint(equalToConstant: 14).isActive = true
            checkmarkContainerView.heightAnchor.constraint(equalToConstant: 22).isActive = true
            horizontalStackView.addArrangedSubview(checkmarkContainerView)

            checkmarkContainerView.addSubview(checkmarkImageView)
            checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
            checkmarkImageView.pin(view: checkmarkContainerView)
        }
    }

    func configure(paymentMethod: PrimerPaymentMethodTokenData, isDeleting: Bool) {
        self.paymentMethod = paymentMethod
        self.isDeleting = isDeleting

        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        let viewModel: VaultPaymentMethodViewModelProtocol = VaultPaymentMethodViewModel()
        isEnabled = viewModel.selectedPaymentMethodId == paymentMethod.id
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

        cardNetworkImageView.image = paymentMethod.cardButtonViewModel?.imageName.image
        cardNetworkImageView.contentMode = .scaleAspectFit

        checkmarkImageView.image = isDeleting ? ImageName.delete.image?.withRenderingMode(.alwaysTemplate) : ImageName.check2.image?.withRenderingMode(.alwaysTemplate)
        checkmarkImageView.tintColor = theme.paymentMethodButton.border.color(for: .selected)
        checkmarkImageView.contentMode = .scaleAspectFit
        checkmarkImageView.isHidden = isDeleting ? false : !isEnabled

        let textColor = theme.paymentMethodButton.text.color
        cardNetworkLabel.text = paymentMethod.cardButtonViewModel?.network
        cardNetworkLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        cardNetworkLabel.textColor = textColor

        cardholderNameLabel.text = paymentMethod.cardButtonViewModel?.cardholder
        cardholderNameLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        cardholderNameLabel.textColor = textColor

        last4DigitsLabel.text = paymentMethod.cardButtonViewModel?.last4
        last4DigitsLabel.textAlignment = .right
        last4DigitsLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        last4DigitsLabel.textColor = textColor

        expiryDateLabel.text = paymentMethod.cardButtonViewModel?.expiry
        expiryDateLabel.textAlignment = .right
        expiryDateLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        expiryDateLabel.textColor = textColor

        contentView.backgroundColor = theme.view.backgroundColor
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
        self.title = Strings.VaultPaymentMethodViewContent.savedPaymentMethodsTitle

        let uiEvent = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .view,
                context: nil,
                extra: nil,
                objectType: .view,
                objectId: nil,
                objectClass: "\(Self.self)",
                place: .paymentMethodsList))
        Analytics.Service.record(event: uiEvent)

        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        rightBarButton = UIButton()
        rightBarButton.setTitle(Strings.Generic.edit, for: .normal)
        rightBarButton.setTitleColor(theme.text.title.color, for: .normal)
        rightBarButton.titleLabel?.numberOfLines = 1
        rightBarButton.titleLabel?.adjustsFontSizeToFitWidth = true
        rightBarButton.titleLabel?.minimumScaleFactor = 0.5
        rightBarButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.pin(view: view)
        tableView.accessibilityIdentifier = "payment_methods_table_view"
        tableView.backgroundColor = theme.view.backgroundColor
        tableView.rowHeight = 46
        tableView.alwaysBounceVertical = false
        tableView.register(VaultedPaymentInstrumentCell.self, forCellReuseIdentifier: "VaultedPaymentInstrumentCell")
        let viewModel: VaultPaymentMethodViewModelProtocol = VaultPaymentMethodViewModel()
        viewModel.reloadVault { _ in

        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (parent as? PrimerContainerViewController)?.mockedNavigationBar.rightBarButton = rightBarButton
    }

    @objc
    func editButtonTapped(_ sender: UIButton) {
        isDeleting = !isDeleting

        if isDeleting {
            let uiEvent = Analytics.Event(
                eventType: .ui,
                properties: UIEventProperties(
                    action: .click,
                    context: nil,
                    extra: nil,
                    objectType: .button,
                    objectId: .cancel,
                    objectClass: "\(UIButton.self)",
                    place: .paymentMethodsList))
            Analytics.Service.record(event: uiEvent)
        } else {
            let uiEvent = Analytics.Event(
                eventType: .ui,
                properties: UIEventProperties(
                    action: .click,
                    context: nil,
                    extra: nil,
                    objectType: .button,
                    objectId: .edit,
                    objectClass: "\(UIButton.self)",
                    place: .paymentMethodsList))
            Analytics.Service.record(event: uiEvent)
        }

        let title = isDeleting ? Strings.Generic.cancel : Strings.Generic.edit
        rightBarButton.setTitle(title, for: .normal)
    }

    private func deletePaymentMethod(_ paymentMethodToken: String) {
        let viewModel: VaultPaymentMethodViewModelProtocol = VaultPaymentMethodViewModel()
        viewModel.deletePaymentMethod(with: paymentMethodToken, and: { [weak self] _ in
            DispatchQueue.main.async {
                self?.delegate?.reload()
                self?.tableView.reloadData()
                // Going back if no payment method remains
                if viewModel.paymentMethods.isEmpty {
                    PrimerUIManager.primerRootViewController?.popViewController()
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
        let viewModel: VaultPaymentMethodViewModelProtocol = VaultPaymentMethodViewModel()
        // That's actually payment instruments
        return viewModel.paymentMethods.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel: VaultPaymentMethodViewModelProtocol = VaultPaymentMethodViewModel()
        let paymentMethod = viewModel.paymentMethods[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "VaultedPaymentInstrumentCell", for: indexPath) as? VaultedPaymentInstrumentCell
        else {
            fatalError()
        }

        cell.configure(paymentMethod: paymentMethod, isDeleting: isDeleting)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewModel: VaultPaymentMethodViewModelProtocol = VaultPaymentMethodViewModel()
        let paymentMethod = viewModel.paymentMethods[indexPath.row]

        if !isDeleting {
            viewModel.selectedPaymentMethodId = paymentMethod.id
            tableView.reloadData()
            // It will reload the payment instrument on the Universal Checkout view.
            delegate?.reload()
        } else {
            let uiEvent = Analytics.Event(
                eventType: .ui,
                properties: UIEventProperties(
                    action: .click,
                    context: nil,
                    extra: nil,
                    objectType: .listItem,
                    objectId: .delete,
                    objectClass: "\(UIButton.self)",
                    place: .paymentMethodsList))
            Analytics.Service.record(event: uiEvent)

            let alert = AlertController(
                title: Strings.Alert.deleteConfirmationButtonTitle,
                message: "",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(
                title: Strings.Generic.cancel,
                style: .cancel,
                handler: { _ in
                    let uiEvent = Analytics.Event(
                        eventType: .ui,
                        properties: UIEventProperties(
                            action: .click,
                            context: nil,
                            extra: "alert_button",
                            objectType: .button,
                            objectId: .cancel,
                            objectClass: "\(UIButton.self)",
                            place: .paymentMethodsList))
                    Analytics.Service.record(event: uiEvent)
                }))

            alert.addAction(UIAlertAction(
                title: Strings.Generic.delete,
                style: .destructive,
                handler: { [weak self] _ in
                    guard let id = paymentMethod.id else { return }
                    self?.deletePaymentMethod(id)
                    let uiEvent = Analytics.Event(
                        eventType: .ui,
                        properties: UIEventProperties(
                            action: .click,
                            context: nil,
                            extra: "alert_button",
                            objectType: .button,
                            objectId: .done,
                            objectClass: "\(UIButton.self)",
                            place: .paymentMethodsList))
                    Analytics.Service.record(event: uiEvent)
                }))

            alert.show()
        }
        tableView.reloadData()
    }
}
