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
    private var banks: [Bank]
    private var tableView: UITableView = UITableView()
//    let tableViewContainer = UIView()
    
    
    init(banks: [Bank]) {
        self.banks = banks
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("primer-bank-selector-nav-bar-title",
                                  tableName: nil,
                                  bundle: Bundle.primerResources,
                                  value: "Banks",
                                  comment: "Banks - Bank Selector Navigation Bar Title")
        
        view.backgroundColor = theme.colorTheme.main1
                
        verticalStackView.spacing = 5
        
        let bankTitleLabel = UILabel()
        bankTitleLabel.text = "Title"
        bankTitleLabel.font = UIFont.systemFont(ofSize: 20)
        bankTitleLabel.textColor = .black
        verticalStackView.addArrangedSubview(bankTitleLabel)
        
        let bankSubtitleLabel = UILabel()
        bankSubtitleLabel.text = "Subtitle"
        bankSubtitleLabel.font = UIFont.systemFont(ofSize: 14)
        bankSubtitleLabel.textColor = .black
        verticalStackView.addArrangedSubview(bankSubtitleLabel)
        
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 5).isActive = true
        verticalStackView.addArrangedSubview(separator)
        
        let tableViewMockView = UIView()
        tableViewMockView.translatesAutoresizingMaskIntoConstraints = false
        tableViewMockView.heightAnchor.constraint(equalToConstant: 400).isActive = true
        verticalStackView.addArrangedSubview(tableViewMockView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if tableView.superview == nil {
            let lastView = verticalStackView.arrangedSubviews.last!
            verticalStackView.removeArrangedSubview(lastView)
            verticalStackView.addArrangedSubview(tableView)
            tableView.heightAnchor.constraint(equalToConstant: 400).isActive = true
            
            if #available(iOS 11.0, *) {
                tableView.contentInsetAdjustmentBehavior = .never
            }

            tableView.rowHeight = 41
            tableView.register(BankTableViewCell.self, forCellReuseIdentifier: BankTableViewCell.identifier)
            tableView.dataSource = self
        }
    }
    
}

extension BankSelectorViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return banks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = banks[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "BankTableViewCell", for: indexPath) as! BankTableViewCell
        cell.configure(viewModel: viewModel)
        return cell
    }
}

class BankTableViewCell: UITableViewCell {
    
    static var identifier: String = "BankTableViewCell"
    
    var stackView = UIStackView()
    var logoImageView = UIImageView()
    var nameLabel = UILabel()
    
    internal private(set) var bank: Bank!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.preservesSuperviewLayoutMargins = false
        self.contentView.preservesSuperviewLayoutMargins = false
        
        contentView.addSubview(stackView)
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 10
        logoImageView.contentMode = .scaleAspectFit
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(logoImageView)
        stackView.addArrangedSubview(nameLabel)
        
        stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0).isActive = true
        stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0).isActive = true
        stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true

        logoImageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        
        nameLabel.numberOfLines = 1
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(viewModel: Bank) {
        self.bank = viewModel
//        logoImageView.image = viewModel.icon
        nameLabel.text = viewModel.name
        
        
        logoImageView.load(url: self.bank.logoUrl!)
    }
}

fileprivate extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}



#endif
