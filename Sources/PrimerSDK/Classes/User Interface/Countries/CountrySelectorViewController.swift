#if canImport(UIKit)

import UIKit

internal class CountrySelectorViewController: PrimerFormViewController {
    
    let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    private var viewModel: SearchableItemsPaymentMethodTokenizationViewModelProtocol!
    private let countries = CountryCode.allCases
    internal private(set) var subtitle: String?
    
    deinit {
        viewModel.cancel()
        viewModel = nil
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
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
                    paymentMethodType: self.viewModel.config.type.rawValue,
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
        
        let bankTitleLabel = UILabel()
        bankTitleLabel.text = NSLocalizedString("choose-your-country-title-label",
                                                tableName: nil,
                                                bundle: Bundle.primerResources,
                                                value: "Choose country",
                                                comment: "Choose country - Choose your billing address country")
        bankTitleLabel.font = UIFont.systemFont(ofSize: 20)
        bankTitleLabel.textColor = theme.text.title.color
        verticalStackView.addArrangedSubview(bankTitleLabel)
        
        verticalStackView.addArrangedSubview(viewModel.searchCountryTextField)
                
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 5).isActive = true
        verticalStackView.addArrangedSubview(separator)
        
        self.verticalStackView.addArrangedSubview(self.viewModel.tableView)
        self.viewModel.tableView.translatesAutoresizingMaskIntoConstraints = false
    }
}

#endif
