import UIKit

internal class CountrySelectorViewController: PrimerFormViewController {

    let theme: PrimerThemeProtocol = DependencyContainer.resolve()

    private var viewModel: SearchableItemsPaymentMethodTokenizationViewModelProtocol!
    private let countries = CountryCode.allCases
    internal private(set) var subtitle: String?

    deinit {
        viewModel.cancel()
        viewModel = nil
    }

    init(viewModel: SearchableItemsPaymentMethodTokenizationViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let viewEvent = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .view,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: self.viewModel.config.type,
                    url: nil),
                extra: nil,
                objectType: .view,
                objectId: nil,
                objectClass: "\(Self.self)",
                place: .countrySelectionList))
        Analytics.Service.record(event: viewEvent)

        view.backgroundColor = theme.view.backgroundColor
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 120+(CGFloat(countries.count)*viewModel.tableView.rowHeight)).isActive = true
        viewModel.tableView.isScrollEnabled = false

        verticalStackView.spacing = 5

        let theme: PrimerThemeProtocol = DependencyContainer.resolve()

        let countryTitleLabel = UILabel()
        countryTitleLabel.text = Strings.CountrySelector.selectCountryTitle
        countryTitleLabel.font = UIFont.systemFont(ofSize: 20)
        countryTitleLabel.textColor = theme.text.title.color
        verticalStackView.addArrangedSubview(countryTitleLabel)

        verticalStackView.addArrangedSubview(viewModel.searchableTextField)

        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 5).isActive = true
        verticalStackView.addArrangedSubview(separator)

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.viewModel.tableView.superview == nil {
            let lastView = self.verticalStackView.arrangedSubviews.last!
            self.verticalStackView.removeArrangedSubview(lastView)
            self.verticalStackView.addArrangedSubview(self.viewModel.tableView)
            self.viewModel.tableView.translatesAutoresizingMaskIntoConstraints = false
        }
    }
}
