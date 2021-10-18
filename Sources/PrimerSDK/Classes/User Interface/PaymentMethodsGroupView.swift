//
//  PaymentMethodsGroupView.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 4/10/21.
//

import UIKit

protocol PaymentMethodsGroupViewDelegate {
    func paymentMethodsGroupView(_ paymentMethodsGroupView: PaymentMethodsGroupView, paymentMethodTapped paymentMethod: PaymentMethodViewModel)
}

class PaymentMethodsGroupView: PrimerView {
    
    internal private(set) var title: String?
    internal private(set) var paymentMethodsViewModels: [PaymentMethodViewModel]!
    private var stackView: UIStackView = UIStackView()
    internal var delegate: PaymentMethodsGroupViewDelegate?
    internal var titleLabel: UILabel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        render()
    }
    
    convenience init(frame: CGRect = .zero, title: String?, paymentMethodsViewModels: [PaymentMethodViewModel]) {
        self.init(frame: frame)
        self.title = title
        self.paymentMethodsViewModels = paymentMethodsViewModels
        render()
    }
    
    func render() {
        backgroundColor = .black.withAlphaComponent(0.05)
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 4.0
        clipsToBounds = true
        
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 7.0
        stackView.pin(view: self, leading: 10, top: 10, trailing: -10, bottom: -10)
        
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        if let title = title {
            titleLabel = UILabel()
            titleLabel!.text = title
            titleLabel!.textAlignment = .right
            titleLabel!.textColor = theme.colorTheme.text1
            stackView.addArrangedSubview(titleLabel!)
        }
        
        for paymentMethodViewModel in paymentMethodsViewModels {
            let paymentMethodButtonView = PaymentMethodButtonView(frame: .zero, viewModel: paymentMethodViewModel)
            paymentMethodButtonView.backgroundColor = .clear
            paymentMethodButtonView.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .medium)
            paymentMethodButtonView.cornerRadius = 4.0
            paymentMethodButtonView.borderWidth = 1.0
            paymentMethodButtonView.borderColor = .clear
            paymentMethodButtonView.clipsToBounds = true
            
            switch paymentMethodViewModel.type {
            case .paymentCard:
                paymentMethodButtonView.setTitleColor(theme.colorTheme.text1, for: .normal)
                paymentMethodButtonView.tintColor = theme.colorTheme.text1
                paymentMethodButtonView.buttonColor = .white
                paymentMethodButtonView.imageEdgeInsets = UIEdgeInsets(top: -2, left: 0, bottom: 0, right: 10)
                paymentMethodButtonView.borderColor = theme.colorTheme.text1
                paymentMethodButtonView.addTarget(self, action: #selector(cardButtonTapped), for: .touchUpInside)
                stackView.addArrangedSubview(paymentMethodButtonView)
                
            case .applePay:
                paymentMethodButtonView.buttonColor = .black
                paymentMethodButtonView.setTitleColor(.white, for: .normal)
                paymentMethodButtonView.tintColor = .white
                paymentMethodButtonView.addTarget(self, action: #selector(applePayButtonTapped(_:)), for: .touchUpInside)
                stackView.addArrangedSubview(paymentMethodButtonView)
                
            case .payPal:
                if #available(iOS 11.0, *) {
                    paymentMethodButtonView.buttonColor = UIColor(red: 0.745, green: 0.894, blue: 0.996, alpha: 1)
                    paymentMethodButtonView.tintColor = .white
                    paymentMethodButtonView.addTarget(self, action: #selector(payPalButtonTapped), for: .touchUpInside)
                    stackView.addArrangedSubview(paymentMethodButtonView)
                }
                
            case .goCardlessMandate:
                paymentMethodButtonView.setTitleColor(theme.colorTheme.text1, for: .normal)
                paymentMethodButtonView.tintColor = theme.colorTheme.text1
                paymentMethodButtonView.buttonColor = .white
                paymentMethodButtonView.imageEdgeInsets = UIEdgeInsets(top: -2, left: 0, bottom: 0, right: 10)
                paymentMethodButtonView.borderColor = theme.colorTheme.text1
                paymentMethodButtonView.addTarget(self, action: #selector(goCardlessButtonTapped), for: .touchUpInside)
                stackView.addArrangedSubview(paymentMethodButtonView)
                
            case .apaya:
                paymentMethodButtonView.setTitleColor(theme.colorTheme.text1, for: .normal)
                paymentMethodButtonView.tintColor = theme.colorTheme.text1
                paymentMethodButtonView.buttonColor = .white
                paymentMethodButtonView.imageEdgeInsets = UIEdgeInsets(top: -2, left: 0, bottom: 0, right: 10)
                paymentMethodButtonView.borderColor = theme.colorTheme.text1
                paymentMethodButtonView.addTarget(self, action: #selector(apayaButtonTapped), for: .touchUpInside)
                stackView.addArrangedSubview(paymentMethodButtonView)
                
            case .klarna:

                paymentMethodButtonView.buttonColor = UIColor(red: 1, green: 0.702, blue: 0.78, alpha: 1)
                paymentMethodButtonView.addTarget(self, action: #selector(klarnaButtonTapped), for: .touchUpInside)
                stackView.addArrangedSubview(paymentMethodButtonView)
                
            default:
                break
            }
        }
    }
    
    @objc
    func applePayButtonTapped(_ sender: UIButton) {
        guard let applePayViewModel = paymentMethodsViewModels.filter({ $0.type == .applePay }).first else { return }
        delegate?.paymentMethodsGroupView(self, paymentMethodTapped: applePayViewModel)
    }
    
    @objc
    func klarnaButtonTapped() {
        guard let klarnaViewModel = paymentMethodsViewModels.filter({ $0.type == .klarna }).first else { return }
        delegate?.paymentMethodsGroupView(self, paymentMethodTapped: klarnaViewModel)
    }
    
    @objc
    func payPalButtonTapped() {
        guard let payPalViewModel = paymentMethodsViewModels.filter({ $0.type == .payPal }).first else { return }
        delegate?.paymentMethodsGroupView(self, paymentMethodTapped: payPalViewModel)
    }
    
    @objc
    func cardButtonTapped() {
        guard let paymentCardViewModel = paymentMethodsViewModels.filter({ $0.type == .paymentCard }).first else { return }
        delegate?.paymentMethodsGroupView(self, paymentMethodTapped: paymentCardViewModel)
    }
    
    @objc
    func apayaButtonTapped() {
        guard let apayaViewModel = paymentMethodsViewModels.filter({ $0.type == .apaya }).first else { return }
        delegate?.paymentMethodsGroupView(self, paymentMethodTapped: apayaViewModel)
    }
    
    @objc
    func goCardlessButtonTapped() {
        guard let goCardlessViewModel = paymentMethodsViewModels.filter({ $0.type == .goCardlessMandate }).first else { return }
        delegate?.paymentMethodsGroupView(self, paymentMethodTapped: goCardlessViewModel)
    }
    
}
