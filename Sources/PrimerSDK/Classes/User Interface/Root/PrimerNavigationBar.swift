//
//  PrimerNavigationBar.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 31/8/21.
//

import UIKit

class PrimerNavigationBar: PrimerView {

    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    internal var hidesBackButton: Bool = false {
        didSet {
            backButton.isHidden = hidesBackButton
        }
    }
    let horizontalStackView = UIStackView()
    let leftView = PrimerView()
    let rightView = PrimerView()
    let backButton = UIButton()

    var rightBarButton: UIButton? {
        didSet {
            rightBarButton?.tintColor = theme.text.system.color
            rightBarButton?.setTitleColor(theme.text.system.color, for: .normal)
            rightBarButton?.frame = CGRect(
                x: 0, y: 0, width: rightView.bounds.size.width, height: rightView.bounds.size.height
            )

            rightView.subviews.forEach { view in
                view.removeFromSuperview()
            }

            if let rightBarButton = rightBarButton {
                rightView.addSubview(rightBarButton)
            }
        }
    }

    private var availableCenterSpaceView = PrimerView()
    private var centerStackView: UIStackView?

    var titleImage: UIImage? {
        didSet {
            guard titleImage != nil else {
                return
            }
            renderCenterComponents()
        }
    }
    var titleImageView: UIImageView?

    var title: String? {
        didSet {
            guard title != nil else {
                return
            }
            renderCenterComponents()
        }
    }
    private var titleLabel: UILabel?

    convenience init() {
        self.init(frame: CGRect.zero)
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: PrimerDimensions.NavigationBar.default))
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func backButtonTapped(_ sender: Any) {
        let uiEvent = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .click,
                context: nil,
                extra: nil,
                objectType: .button,
                objectId: .back,
                objectClass: "\(UIButton.self)",
                place: .vaultManager))
        Analytics.Service.record(event: uiEvent)

        PrimerUIManager.primerRootViewController?.popViewController()
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: PrimerDimensions.NavigationBar.default).isActive = true
        backgroundColor = theme.view.backgroundColor

        let theme: PrimerThemeProtocol = DependencyContainer.resolve()

        backButton.translatesAutoresizingMaskIntoConstraints = false
        let image = UILocalizableUtil.isRightToLeftLocale ? PrimerImage.backIconRTL.image : PrimerImage.backIcon.image
        let customColorImage = image?.withRenderingMode(.alwaysTemplate)
        backButton.setImage(customColorImage, for: .normal)
        backButton.tintColor = theme.colors.primary
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.accessibilityIdentifier = AccessibilityIdentifier.General.backButton.rawValue

        leftView.addSubview(backButton)

        backButton.pin(view: leftView)
        backButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        backButton.isHidden = hidesBackButton

        addSubview(horizontalStackView)

        horizontalStackView.translatesAutoresizingMaskIntoConstraints = false
        horizontalStackView.pin(view: self, leading: 8.0, top: 0, trailing: -8.0, bottom: 0)
        horizontalStackView.alignment = .fill
        horizontalStackView.axis = .horizontal
        horizontalStackView.distribution = .fill
        horizontalStackView.spacing = 8.0

        leftView.translatesAutoresizingMaskIntoConstraints = false
        leftView.widthAnchor.constraint(equalToConstant: 60).isActive = true
        leftView.heightAnchor.constraint(equalToConstant: PrimerDimensions.NavigationBar.default).isActive = true
        leftView.backgroundColor = .clear
        horizontalStackView.addArrangedSubview(leftView)

        horizontalStackView.addArrangedSubview(availableCenterSpaceView)
        renderCenterComponents()

        rightView.translatesAutoresizingMaskIntoConstraints = false
        rightView.widthAnchor.constraint(equalToConstant: 60).isActive = true
        rightView.heightAnchor.constraint(equalToConstant: PrimerDimensions.NavigationBar.default).isActive = true
        rightView.backgroundColor = .clear
        horizontalStackView.addArrangedSubview(rightView)
    }

    func renderCenterComponents() {
        availableCenterSpaceView.removeSubviews()
        initializeCenterStackViewIfNeeded()
        renderTitleLabelIfNeeded()
        renderImageViewIfNeeded()
    }
}

extension PrimerNavigationBar {

    private func renderImageViewIfNeeded() {

        guard let titleImage = titleImage else {
            return
        }

        titleImageView = UIImageView()
        titleImageView?.image = titleImage
        titleImageView?.contentMode = .scaleAspectFit
        titleImageView?.clipsToBounds = true
        titleImageView?.translatesAutoresizingMaskIntoConstraints = false
        centerStackView?.addArrangedSubview(titleImageView!)
    }

    private func renderTitleLabelIfNeeded() {

        guard let title = title else {
            return
        }

        titleLabel = UILabel()
        titleLabel?.text = title
        titleLabel?.backgroundColor = .clear
        titleLabel?.textAlignment = .center
        titleLabel?.textColor = theme.text.title.color
        titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.minimumScaleFactor = 0.65
        centerStackView?.addArrangedSubview(titleLabel!)
    }

    private func initializeCenterStackViewIfNeeded() {

        if centerStackView == nil {
            centerStackView = UIStackView()
            centerStackView!.axis = .horizontal
            centerStackView!.alignment = .fill
            centerStackView!.distribution = .fill
            centerStackView!.spacing = 6.0
            centerStackView!.alpha = 0.0
            centerStackView!.translatesAutoresizingMaskIntoConstraints = false
        }

        availableCenterSpaceView.addSubview(centerStackView!)
        centerStackView?.pin(view: availableCenterSpaceView, leading: 0, top: 4, trailing: 0, bottom: -4)
        centerStackView?.centerXAnchor.constraint(equalTo: availableCenterSpaceView.centerXAnchor).isActive = true
        UIView.animate(withDuration: 0.3) {
            self.centerStackView?.alpha = 1.0
        } completion: { _ in }
    }
}
