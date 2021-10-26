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
    
    private let viewModel: BankSelectorViewModel
    internal private(set) var subtitle: String?
    
    init(banks: [Bank], title: String?, subtitle: String?) {
        self.banks = banks
        viewModel = BankSelectorViewModel(banks: banks)
        super.init(nibName: nil, bundle: nil)
        self.title = title
        self.subtitle = subtitle
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = theme.colorTheme.main1
                
        verticalStackView.spacing = 5
        
        let bankTitleLabel = UILabel()
        bankTitleLabel.text = NSLocalizedString("choose-your-bank-title-label",
                                                tableName: nil,
                                                bundle: Bundle.primerResources,
                                                value: "Choose your bank",
                                                comment: "Choose your bank - Choose your bank title label")
        bankTitleLabel.font = UIFont.systemFont(ofSize: 20)
        bankTitleLabel.textColor = .black
        verticalStackView.addArrangedSubview(bankTitleLabel)
        
        if let subtitle = subtitle {
            let bankSubtitleLabel = UILabel()
            bankSubtitleLabel.text = subtitle
            bankSubtitleLabel.font = UIFont.systemFont(ofSize: 14)
            bankSubtitleLabel.textColor = .black
            verticalStackView.addArrangedSubview(bankSubtitleLabel)
        }
        
        verticalStackView.addArrangedSubview(viewModel.searchBankTextField!)
        
        let separator2 = UIView()
        separator2.translatesAutoresizingMaskIntoConstraints = false
        separator2.heightAnchor.constraint(equalToConstant: 5).isActive = true
        verticalStackView.addArrangedSubview(separator2)
        
        let tableViewMockView = UIView()
        tableViewMockView.translatesAutoresizingMaskIntoConstraints = false
        tableViewMockView.heightAnchor.constraint(equalToConstant: 400).isActive = true
        verticalStackView.addArrangedSubview(tableViewMockView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if viewModel.tableView.superview == nil {
            let lastView = verticalStackView.arrangedSubviews.last!
            verticalStackView.removeArrangedSubview(lastView)
            verticalStackView.addArrangedSubview(viewModel.tableView)
            viewModel.tableView.heightAnchor.constraint(equalToConstant: 400).isActive = true
        }
    }
    
}

#endif
