//
//  BankSelectorUI.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 25/10/21.
//

#if canImport(UIKit)

import UIKit

internal class BankSelectorViewController: PrimerFormViewController {
    
    let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    private var paymentMethodType: String
    private var navigationBarImage: UIImage?
    internal private(set) var subtitle: String?
    internal var didSelectBank: ((_ bank: AdyenBank) -> Void)?
    
    var banks: [AdyenBank]
    private var dataSource: [AdyenBank] = [] {
        didSet {
            tableView.reloadData()
        }
    }
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
        tableView.register(BankTableViewCell.self, forCellReuseIdentifier: BankTableViewCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    
    internal lazy var searchBankTextField: PrimerSearchTextField = {
        let textField = PrimerSearchTextField(frame: .zero)
        textField.delegate = self
        textField.borderStyle = .none
        textField.layer.cornerRadius = 3.0
        textField.font = UIFont.systemFont(ofSize: 16.0)
        textField.placeholder = Strings.BankSelector.searchBankTitle
        textField.rightViewMode = .always
        return textField
    }()
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    init(
        paymentMethodType: String,
        navigationBarImage: UIImage?,
        banks: [AdyenBank]
    ) {
        self.paymentMethodType = paymentMethodType
        self.navigationBarImage = navigationBarImage
        self.banks = banks
        super.init(nibName: nil, bundle: nil)
        self.titleImage = self.navigationBarImage
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dataSource = self.banks
        
        let viewEvent = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .view,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: self.paymentMethodType,
                    url: nil),
                extra: nil,
                objectType: .view,
                objectId: nil,
                objectClass: "\(Self.self)",
                place: .bankSelectionList))
        Analytics.Service.record(event: viewEvent)

        view.backgroundColor = theme.view.backgroundColor
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 120+(CGFloat(self.banks.count)*self.tableView.rowHeight)).isActive = true
        self.tableView.isScrollEnabled = false
                
        verticalStackView.spacing = 5
        
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        let bankTitleLabel = UILabel()
        bankTitleLabel.text = Strings.BankSelector.chooseBankTitle
        bankTitleLabel.font = UIFont.systemFont(ofSize: 20)
        bankTitleLabel.textColor = theme.text.title.color
        verticalStackView.addArrangedSubview(bankTitleLabel)
        
        if let subtitle = subtitle {
            let bankSubtitleLabel = UILabel()
            bankSubtitleLabel.text = subtitle
            bankSubtitleLabel.font = UIFont.systemFont(ofSize: 14)
            bankSubtitleLabel.textColor = .black
            verticalStackView.addArrangedSubview(bankSubtitleLabel)
        }
        
        verticalStackView.addArrangedSubview(self.searchBankTextField)
        
        self.searchBankTextField.translatesAutoresizingMaskIntoConstraints = false
        self.searchBankTextField.heightAnchor.constraint(equalToConstant: 35).isActive = true
        
        let separator2 = UIView()
        separator2.translatesAutoresizingMaskIntoConstraints = false
        separator2.heightAnchor.constraint(equalToConstant: 5).isActive = true
        verticalStackView.addArrangedSubview(separator2)
        
        let tableViewMockView = UIView()
        tableViewMockView.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.addArrangedSubview(tableViewMockView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            if self.tableView.superview == nil {
                let lastView = self.verticalStackView.arrangedSubviews.last!
                self.verticalStackView.removeArrangedSubview(lastView)
                self.verticalStackView.addArrangedSubview(self.tableView)
                self.tableView.translatesAutoresizingMaskIntoConstraints = false
            }
        }
    }
    
}

extension BankSelectorViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let bank = dataSource[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "BankTableViewCell", for: indexPath) as! BankTableViewCell
        cell.configure(viewModel: bank)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let bank = self.dataSource[indexPath.row]
        self.didSelectBank?(bank)
    }
}

extension BankSelectorViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "\n" {
            // Keyboard's return button tapoped
            textField.resignFirstResponder()
            return false
        }
        
        var query: String
        
        if string.isEmpty {
            query = String((textField.text ?? "").dropLast())
        } else {
            query = (textField.text ?? "") + string
        }
        
        if query.isEmpty {
            dataSource = banks
            return true
        }
        
        var bankResults: [AdyenBank] = []
        
        for bank in banks {
            if bank.name.lowercased().folding(options: .diacriticInsensitive, locale: nil).contains(query.lowercased().folding(options: .diacriticInsensitive, locale: nil)) == true {
                bankResults.append(bank)
            }
        }
        
        dataSource = bankResults
        
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        dataSource = banks
        return true
    }
}

#endif
