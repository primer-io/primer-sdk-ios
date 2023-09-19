

import UIKit

class CountryTableViewCell: UITableViewCell {
        
    var stackView = UIStackView()
    var flag = UILabel()
    var nameLabel = UILabel()
    
    internal private(set) var countryCode: CountryCode!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.preservesSuperviewLayoutMargins = false
        self.contentView.preservesSuperviewLayoutMargins = false
        self.selectionStyle = .none
        
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        backgroundColor = theme.view.backgroundColor
        
        contentView.addSubview(stackView)
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 10
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        flag.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(flag)
        stackView.addArrangedSubview(nameLabel)
        
        stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0).isActive = true
        stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0).isActive = true
        stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true

        flag.widthAnchor.constraint(equalToConstant: 20).isActive = true
        
        nameLabel.numberOfLines = 1
        nameLabel.textColor = theme.text.body.color
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(viewModel: CountryCode) {
        self.countryCode = viewModel
        nameLabel.text = viewModel.country
        flag.text = viewModel.flag
    }
}


