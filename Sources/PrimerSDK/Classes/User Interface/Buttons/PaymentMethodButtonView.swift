//
//  PaymentMethodButton.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 1/10/21.
//

import UIKit

class PaymentMethodButtonView: PrimerView {
    
    internal private(set) var surCharge: String?
    internal private(set) var title: String?
    internal private(set) var image: UIImage?
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return button.layer.cornerRadius
        }
        set {
            button.layer.cornerRadius = newValue
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return button.layer.borderWidth
        }
        set {
            button.layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            if let cgColor = button.layer.borderColor {
                return UIColor(cgColor: cgColor)
            } else {
                return nil
            }
        }
        set {
            button.layer.borderColor = newValue?.cgColor
        }
    }
    
    override var tintColor: UIColor! {
        get {
            return button.tintColor
        }
        set {
            button?.tintColor = newValue
        }
    }
    var imageEdgeInsets: UIEdgeInsets = .zero {
        didSet {
            button.imageEdgeInsets = imageEdgeInsets
        }
    }
    
    var contentEdgeInsets: UIEdgeInsets = .zero {
        didSet {
            button.contentEdgeInsets = contentEdgeInsets
        }
    }
    
    var titleEdgeInsets: UIEdgeInsets = .zero {
        didSet {
            button.titleEdgeInsets = titleEdgeInsets
        }
    }
    var titleLabel: UILabel? {
        return button.titleLabel
    }
    
    var verticalStackView = UIStackView()
    var button: UIButton! = UIButton()
    
    var buttonColor: UIColor? {
        didSet {
            button?.backgroundColor = buttonColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        render()
    }
    
    private convenience init(frame: CGRect, title: String?, image: UIImage?, surCharge: String?) {
        self.init(frame: frame)
        self.title = title
        self.image = image
        self.surCharge = surCharge
        render()
    }
    
    internal private(set) var paymentMethodViewModel: PaymentMethodViewModel!
    
    convenience init(frame: CGRect, viewModel: PaymentMethodViewModel) {
        self.init(frame: frame)
        self.paymentMethodViewModel = viewModel
        self.title = viewModel.buttonTitle
        self.image = viewModel.buttonImage
        self.surCharge = viewModel.surCharge
        render()
    }
    
    func render() {
        translatesAutoresizingMaskIntoConstraints = false
        
        backgroundColor = .clear
        button.tintColor = tintColor
        
        addSubview(verticalStackView)
        verticalStackView.axis = .vertical
        verticalStackView.alignment = .fill
        verticalStackView.distribution = .fill
        verticalStackView.spacing = 3
        
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.pin(view: self)
        
        button.heightAnchor.constraint(equalToConstant: 45).isActive = true
        button.setTitleColor(UIColor.systemBlue, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .medium)
        button.layer.cornerRadius = 4.0
        
        if let title = title {
            setTitle(title, for: .normal)
        }
        if let image = image {
            setImage(image, for: .normal)
            button.imageEdgeInsets = UIEdgeInsets(top: title != nil ? 14 : 4, left: 0, bottom: title != nil ? 14 : 4, right: 4)
        }
        
        verticalStackView.addArrangedSubview(button)
        
        layoutIfNeeded()
        
        button.imageView?.contentMode = .scaleAspectFit
    }
    
    func setTitle(_ title: String?, for state: UIControl.State) {
        button.setTitle(title, for: state)
    }
    
    func setTitleColor(_ color: UIColor?, for state: UIControl.State) {
        button.setTitleColor(color, for: state)
    }
    
    func setImage(_ image: UIImage?, for state: UIControl.State) {
        button.setImage(image, for: state)
    }
    
    func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        button.addTarget(target, action: action, for: controlEvents)
    }
    
}


