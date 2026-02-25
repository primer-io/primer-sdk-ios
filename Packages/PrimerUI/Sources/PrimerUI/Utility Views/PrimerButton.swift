//
//  PrimerButton.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerUI
import UIKit

///
/// Reserve the name for all primer buttons. If you need to extend UIButton, extend and use this one instead, so we
/// don't expose unnecessary functionality.
///
@IBDesignable open class PrimerButton: UIButton, Identifiable {

    // MARK: @IBInspectable Properties

    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            let maxRadius = min(frame.width, frame.height) / 2
            layer.cornerRadius = cornerRadius > maxRadius ? maxRadius : cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }

    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }

    @IBInspectable var borderColor: UIColor? {
        didSet {
            layer.borderColor = borderColor?.cgColor
        }
    }

    @IBInspectable var backgroundNormalStateColor: UIColor? {
        didSet {
            backgroundColor = backgroundNormalStateColor
        }
    }

    @IBInspectable var backgroundHighlightedStateColor: UIColor?

    // MARK: Properties

    public var id: String?

    private var theme: ButtonTheme?

    var imageLogo: UIImage? {
        didSet {
            if let image = imageLogo {
                setImage(image, for: .normal)
            }
        }
    }

    var title: String? {
        didSet {
            setTitle(title, for: .normal)
        }
    }

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

    // MARK: - Button States for Activity Indicator

    struct ActivityIndicatorButtonState {
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
        let xCenterConstraint = NSLayoutConstraint(item: self,
                                                   attribute: .centerX,
                                                   relatedBy: .equal,
                                                   toItem: activityIndicator,
                                                   attribute: .centerX,
                                                   multiplier: 1,
                                                   constant: 0)
        let yCenterConstraint = NSLayoutConstraint(item: self,
                                                   attribute: .centerY,
                                                   relatedBy: .equal,
                                                   toItem: activityIndicator,
                                                   attribute: .centerY,
                                                   multiplier: 1,
                                                   constant: 0)
        self.addConstraints([xCenterConstraint, yCenterConstraint])
        return activityIndicator
    }()

    override public func layoutSubviews() {
        super.layoutSubviews()
        setupStyleBasedOnCustomThemeIfNeeded()
    }
}

// MARK: - Setup

extension PrimerButton {

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

// MARK: Activity Indicator

public extension PrimerButton {

    var isAnimating: Bool {
        activityIndicator.isAnimating
    }

    func startAnimating() {
        if activityIndicator.isAnimating { return }
        DispatchQueue.main.async {

            self.activityIndicator.startAnimating()
            var buttonStates: [ActivityIndicatorButtonState] = []
            for state in [UIControl.State.disabled] {
                let buttonState = ActivityIndicatorButtonState(state: state, title: self.title(for: state), image: self.image(for: state))
                buttonStates.append(buttonState)
                self.setTitle("", for: state)
                self.setImage(UIImage(), for: state)
            }
            self.activityIndicatorButtonStates = buttonStates
            self.isEnabled = false
        }
    }

    func stopAnimating() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            for buttonState in self.activityIndicatorButtonStates {
                self.setTitle(buttonState.title, for: buttonState.state)
                self.setImage(buttonState.image, for: buttonState.state)
            }
            self.isEnabled = true
        }
    }
}
