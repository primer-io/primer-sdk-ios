#if canImport(UIKit)

import UIKit

internal protocol SearchableItemsPaymentMethodTokenizationViewModelProtocol {
    
    var tableView: UITableView { get set }
    var searchableTextField: PrimerSearchTextField { get set }
    
    func cancel()
}

internal class CountrySelectorViewController: PrimerFormViewController {
    
    let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    private var delegate: SearchableItemsPaymentMethodTokenizationViewModelProtocol!
    private let countries = CountryCode.allCases
    internal private(set) var subtitle: String?
    private var paymentMethod: PrimerPaymentMethod
    
    deinit {
        delegate.cancel()
        delegate = nil
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    init(delegate: SearchableItemsPaymentMethodTokenizationViewModelProtocol, paymentMethod: PrimerPaymentMethod) {
        self.delegate = delegate
        self.paymentMethod = paymentMethod
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
                    paymentMethodType: self.paymentMethod.type,
                    url: nil),
                extra: nil,
                objectType: .view,
                objectId: nil,
                objectClass: "\(Self.self)",
                place: .countrySelectionList))
        Analytics.Service.record(event: viewEvent)

        view.backgroundColor = theme.view.backgroundColor
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 120+(CGFloat(countries.count)*delegate.tableView.rowHeight)).isActive = true
        delegate.tableView.isScrollEnabled = false
                
        verticalStackView.spacing = 5
        
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        let bankTitleLabel = UILabel()
        bankTitleLabel.text = Strings.CountrySelector.selectCountryTitle
        bankTitleLabel.font = UIFont.systemFont(ofSize: 20)
        bankTitleLabel.textColor = theme.text.title.color
        verticalStackView.addArrangedSubview(bankTitleLabel)
        
        verticalStackView.addArrangedSubview(delegate.searchableTextField)
                
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 5).isActive = true
        verticalStackView.addArrangedSubview(separator)
        
        self.verticalStackView.addArrangedSubview(self.delegate.tableView)
        self.delegate.tableView.translatesAutoresizingMaskIntoConstraints = false
    }
}

#endif
