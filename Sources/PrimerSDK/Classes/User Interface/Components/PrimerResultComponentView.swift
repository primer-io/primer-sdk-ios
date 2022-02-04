//
//  PrimerResultView.swift
//  PrimerSDK
//
//  Created by Evangelos on 3/2/22.
//

#if canImport(UIKit)

import UIKit

class PrimerResultComponentView: PrimerView {
    
    private(set) internal var stackView = UIStackView()
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
        addSubview(stackView)
        
        stackView.axis = .vertical
        stackView.spacing = 20.0
        stackView.alignment = .center
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        stackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor).isActive = true
        stackView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        if let imageView = imageView {
            stackView.addArrangedSubview(imageView)
        }
        
        if let message = message {
            let messageLabel = UILabel()
            messageLabel.text = message
            messageLabel.numberOfLines = 0
            messageLabel.font = .systemFont(ofSize: 16)
            messageLabel.textColor = UIColor(red: 142.0/255, green: 142.0/255, blue: 147.0/255, alpha: 1.0)
            messageLabel.textAlignment = .center
            stackView.addArrangedSubview(messageLabel)
        }
        
        if let loadingIndicator = loadingIndicator {
            stackView.addArrangedSubview(loadingIndicator)
        }
    }
    
    convenience init(frame: CGRect = .zero, imageView: UIImageView? = nil, message: String? = nil, loadingIndicator: UIActivityIndicatorView? = nil) {
        self.init(frame: frame)
        self.imageView = imageView
        self.message = message
        self.loadingIndicator = loadingIndicator
        self.initialize()
    }

//    convenience init(frame: CGRect = .zero, title: String?, paymentMethodTokenizationViewModels: [PaymentMethodTokenizationViewModelProtocol]) {
//        self.init(frame: frame)
//        self.title = title
//        self.paymentMethodTokenizationViewModels = paymentMethodTokenizationViewModels
//        render()
//    }
    
//    func render() {
//        backgroundColor = UIColor.black.withAlphaComponent(0.05)
//        translatesAutoresizingMaskIntoConstraints = false
//        layer.cornerRadius = 4.0
//        clipsToBounds = true
//
//        addSubview(stackView)
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//        stackView.axis = .vertical
//        stackView.alignment = .fill
//        stackView.distribution = .fill
//        stackView.spacing = 7.0
//        stackView.pin(view: self, leading: 10, top: 10, trailing: -10, bottom: -10)
//
//        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
//
//        if let title = title {
//            titleLabel = UILabel()
//            titleLabel!.text = title
//            titleLabel!.textAlignment = .right
//            titleLabel!.textColor = theme.text.title.color
//            stackView.addArrangedSubview(titleLabel!)
//        }
//
//        for viewModel in paymentMethodTokenizationViewModels {
//            stackView.addArrangedSubview(viewModel.paymentMethodButton)
//        }
//    }
    
}

#endif
