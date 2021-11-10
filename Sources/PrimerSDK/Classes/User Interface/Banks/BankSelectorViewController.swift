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
    
    private let viewModel: BankSelectorTokenizationViewModel
    internal private(set) var subtitle: String?
    
    init(viewModel: BankSelectorTokenizationViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.titleImage = viewModel.buttonImage!
        self.titleImageTintColor = viewModel.buttonTintColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = theme.colorTheme.main1
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 120+(CGFloat(viewModel.banks.count)*viewModel.tableView.rowHeight)).isActive = true
        viewModel.tableView.isScrollEnabled = false
                
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
        verticalStackView.addArrangedSubview(tableViewMockView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            if self.viewModel.tableView.superview == nil {
                let lastView = self.verticalStackView.arrangedSubviews.last!
                self.verticalStackView.removeArrangedSubview(lastView)
                self.verticalStackView.addArrangedSubview(self.viewModel.tableView)
                self.viewModel.tableView.translatesAutoresizingMaskIntoConstraints = false
            }
        }
    }
    
}

#endif
