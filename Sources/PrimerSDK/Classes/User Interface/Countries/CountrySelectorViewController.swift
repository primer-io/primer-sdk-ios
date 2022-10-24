#if canImport(UIKit)

import UIKit

internal class CountrySelectorViewController: PrimerFormViewController {
    
    let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    private let countries = CountryCode.allCases
    var dataSource = CountryCode.allCases {
        didSet {
            tableView.reloadData()
        }
    }
    
    internal private(set) var subtitle: String?
    private var paymentMethodType: String
    
    internal var didSelectCountryCode: ((_ countryCode: CountryCode) -> Void)?
    
    internal lazy var tableView: UITableView = {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        let tableView = UITableView()
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.backgroundColor = theme.view.backgroundColor
        
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }

        tableView.rowHeight = 41
        tableView.register(CountryTableViewCell.self, forCellReuseIdentifier: CountryTableViewCell.className)
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    
    internal lazy var searchableTextField: PrimerSearchTextField = {
        let textField = PrimerSearchTextField(frame: .zero)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.heightAnchor.constraint(equalToConstant: 35).isActive = true
        textField.delegate = self
        textField.borderStyle = .none
        textField.layer.cornerRadius = 3.0
        textField.font = UIFont.systemFont(ofSize: 16.0)
        textField.placeholder = Strings.CountrySelector.searchCountryTitle
        textField.rightViewMode = .always
        return textField
    }()
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    init(paymentMethodType: String) {
        self.paymentMethodType = paymentMethodType
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.verticalStackView.addArrangedSubview(self.tableView)
        
        let viewEvent = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .view,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: paymentMethodType,
                    url: nil),
                extra: nil,
                objectType: .view,
                objectId: nil,
                objectClass: "\(Self.self)",
                place: .countrySelectionList))
        Analytics.Service.record(event: viewEvent)

        view.backgroundColor = theme.view.backgroundColor
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 120+(CGFloat(countries.count)*self.tableView.rowHeight)).isActive = true
        self.tableView.isScrollEnabled = false
                
        verticalStackView.spacing = 5
        
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        let countryTitleLabel = UILabel()
        countryTitleLabel.text = Strings.CountrySelector.selectCountryTitle
        countryTitleLabel.font = UIFont.systemFont(ofSize: 20)
        countryTitleLabel.textColor = theme.text.title.color
        verticalStackView.addArrangedSubview(countryTitleLabel)
        
        verticalStackView.addArrangedSubview(self.searchableTextField)
                
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

#endif
