//
//  BankTableViewCell.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 25/10/21.
//

#if canImport(UIKit)

import UIKit

class BankTableViewCell: UITableViewCell {
    
    static var identifier: String = "BankTableViewCell"
    
    var stackView = UIStackView()
    var logoImageView = UIImageView()
    var nameLabel = UILabel()
    var arrowImageView = UIImageView()
    
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
        arrowImageView.contentMode = .center
        
        arrowImageView.image = UIImage(named: "right-arrow-icon", in: Bundle.primerResources, compatibleWith: nil)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(logoImageView)
        stackView.addArrangedSubview(nameLabel)
        stackView.addArrangedSubview(arrowImageView)
        
        stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0).isActive = true
        stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0).isActive = true
        stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true

        logoImageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        arrowImageView.widthAnchor.constraint(equalToConstant: 11).isActive = true
        
        nameLabel.numberOfLines = 1
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(viewModel: Bank) {
        self.bank = viewModel
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
