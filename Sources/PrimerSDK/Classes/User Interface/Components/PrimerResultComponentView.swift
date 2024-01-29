//
//  PrimerResultView.swift
//  PrimerSDK
//
//  Created by Evangelos on 3/2/22.
//

import UIKit

class PrimerResultComponentView: PrimerView {

    private(set) internal var verticalStackView = UIStackView()
    private(set) internal var imageView: UIImageView?
    private(set) internal var message: String?
    private(set) internal var loadingIndicator: UIActivityIndicatorView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }

    fileprivate func initialize() {
        addSubview(verticalStackView)

        verticalStackView.axis = .vertical
        verticalStackView.spacing = 20.0
        verticalStackView.alignment = .center

        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        verticalStackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor).isActive = true
        verticalStackView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        verticalStackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor).isActive = true
        verticalStackView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        if let imageView = imageView {
            verticalStackView.addArrangedSubview(imageView)
        }

        if let message = message {
            let messageLabel = UILabel()
            messageLabel.text = message
            messageLabel.accessibilityIdentifier = "Result Component View Message Label"
            messageLabel.numberOfLines = 0
            messageLabel.font = .systemFont(ofSize: 16)
            messageLabel.textColor = UIColor(red: 142.0/255, green: 142.0/255, blue: 147.0/255, alpha: 1.0)
            messageLabel.textAlignment = .center
            verticalStackView.addArrangedSubview(messageLabel)
        }

        if let loadingIndicator = loadingIndicator {
            verticalStackView.addArrangedSubview(loadingIndicator)
        }
    }

    convenience init(frame: CGRect = .zero, imageView: UIImageView? = nil, message: String? = nil, loadingIndicator: UIActivityIndicatorView? = nil) {
        self.init(frame: frame)
        self.imageView = imageView
        self.message = message
        self.loadingIndicator = loadingIndicator
        self.initialize()
    }

}
