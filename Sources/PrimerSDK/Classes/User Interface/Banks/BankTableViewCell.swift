//
//  BankTableViewCell.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 25/10/21.
//

import UIKit

class BankTableViewCell: UITableViewCell {

    static var identifier: String = "BankTableViewCell"

    var stackView = UIStackView()
    var logoImageView = UIImageView()
    var nameLabel = UILabel()
    var arrowImageView = UIImageView()

    internal private(set) var bank: AdyenBank!

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
        nameLabel.textColor = theme.text.body.color
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(viewModel: AdyenBank) {
        self.bank = viewModel
        nameLabel.text = viewModel.name
        logoImageView.image = nil
        logoImageView.load(url: self.bank.iconUrl)
    }
}

fileprivate extension UIImageView {
    func load(url: URL?, placeholder: UIImage? = nil) {
        guard let url = url else { return }
        let request = URLRequest(url: url)
        if let data = URLCache.shared.cachedResponse(for: request)?.data, let image = UIImage(data: data) {
            self.image = image
        } else {
            self.image = placeholder
            URLSession.shared.dataTask(with: request, completionHandler: { (data, response, _) in
                if let data = data, let response = response, ((response as? HTTPURLResponse)?.statusCode ?? 500) < 300, let image = UIImage(data: data) {
                    let cachedData = CachedURLResponse(response: response, data: data)
                    URLCache.shared.storeCachedResponse(cachedData, for: request)

                    DispatchQueue.main.async {
                        self.image = image
                    }
                }
            }).resume()
        }
    }
}
