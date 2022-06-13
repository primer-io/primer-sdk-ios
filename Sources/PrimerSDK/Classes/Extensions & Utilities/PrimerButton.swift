//
//  UIButtonExtension.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 18/3/21.
//

#if canImport(UIKit)

import UIKit

///
/// Reserve the name for all primer buttons. If you need to extend UIButton, extend and use this one instead, so we
/// don't expose unnecessary functionality.
///
@IBDesignable internal class PrimerButton: UIButton, Identifiable {
    
    //MARK: @IBInspectable Properties
        
    @IBInspectable internal var cornerRadius: CGFloat = 0 {
        didSet {
            let maxRadius = min(frame.width, frame.height) / 2
            layer.cornerRadius = cornerRadius > maxRadius ? maxRadius : cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
    
    @IBInspectable internal var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable internal var borderColor: UIColor? {
        didSet {
            layer.borderColor = borderColor?.cgColor
        }
    }
    
    @IBInspectable internal var backgroundNormalStateColor: UIColor? {
        didSet {
            backgroundColor = backgroundNormalStateColor
        }
    }
    
    @IBInspectable internal var backgroundHighlightedStateColor: UIColor?
    
    //MARK: Properties

    public var id: String?

    private var theme: ButtonTheme?
    
    internal var imageLogo: UIImage? {
        didSet {
            if let image = imageLogo {
                setImage(image, for: .normal)
            }
        }
    }
    
    internal var title: String? {
        didSet {
            setTitle(title, for: .normal)
        }
    }
    
    internal var onPressed: PrimerAction?
    
    override open var isHighlighted: Bool {
        didSet {
            if !oldValue {
                backgroundNormalStateColor = backgroundColor ?? .clear
            }
            if let backgroundHighlightedColor = backgroundHighlightedStateColor {
                backgroundColor = isHighlighted ? backgroundHighlightedColor : backgroundHighlightedStateColor
            }
        }
    }
    
    //MARK: - Button States for Activity Indicator
    
    internal struct ActivityIndicatorButtonState {
        var state: UIControl.State
        var title: String?
        var image: UIImage?
    }

    private(set) var activityIndicatorButtonStates: [ActivityIndicatorButtonState] = []
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = theme?.colorStates.color(for: .selected) ?? .white
        self.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        let xCenterConstraint = NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: activityIndicator, attribute: .centerX, multiplier: 1, constant: 0)
        let yCenterConstraint = NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: activityIndicator, attribute: .centerY, multiplier: 1, constant: 0)
        self.addConstraints([xCenterConstraint, yCenterConstraint])
        return activityIndicator
    }()

    
    //MARK: - Initializers
    
    convenience init(theme: ButtonTheme? = nil,
                     title: String? = nil,
                     imageLogo: UIImage? = nil) {
        self.init()
        self.setupView(theme: theme, title: title, imageLogo: imageLogo)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addTarget(self, action: #selector(onButtonPressed), for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addTarget(self, action: #selector(onButtonPressed), for: .touchUpInside)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        setupStyleBasedOnCustomThemeIfNeeded()
    }
}

//MARK: - Setup

extension PrimerButton {
    
    private func setupView(theme: ButtonTheme?,
                           title: String?,
                           imageLogo: UIImage?) {
        self.theme = theme
        self.title = title ?? Strings.PaymentButton.pay
        self.imageLogo = imageLogo
    }
    
    private func setupStyleBasedOnCustomThemeIfNeeded() {
        
        guard let theme = theme else {
            return
        }
        

        setTitleColor(theme.color(for: .enabled), for: .normal)
        backgroundNormalStateColor = theme.colorStates.color(for: .enabled)
        backgroundHighlightedStateColor = theme.colorStates.color(for: .selected)
        borderColor = theme.border.color(for: .enabled)
        cornerRadius = theme.cornerRadius
        borderWidth = theme.border.width
    }
}

//MARK: - Action

extension PrimerButton {
    
    @objc
    private func onButtonPressed() {
        onPressed?()
    }
    
}

// MARK: Activity Indicator

extension PrimerButton {
    
    func startAnimating() {
        activityIndicator.startAnimating()
        var buttonStates: [ActivityIndicatorButtonState] = []
        for state in [UIControl.State.disabled] {
            let buttonState = ActivityIndicatorButtonState(state: state, title: title(for: state), image: image(for: state))
            buttonStates.append(buttonState)
            setTitle("", for: state)
            setImage(UIImage(), for: state)
        }
        self.activityIndicatorButtonStates = buttonStates
        isEnabled = false
    }

    func stopAnimating() {
        activityIndicator.stopAnimating()
        for buttonState in activityIndicatorButtonStates {
            setTitle(buttonState.title, for: buttonState.state)
            setImage(buttonState.image, for: buttonState.state)
        }
        isEnabled = true
    }
}

#endif
