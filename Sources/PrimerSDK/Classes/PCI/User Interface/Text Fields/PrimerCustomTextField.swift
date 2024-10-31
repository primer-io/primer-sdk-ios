//
//  PrimerCustomTextField.swift
//  PrimerSDK
//
//  Created by Boris on 25.3.24..
//

import UIKit

class PrimerCustomFieldView: UIView {

    // MARK: - Properties

    var fieldView: PrimerTextFieldView!
    var cardNetworks: [PrimerCardNetwork] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.updateNetworksDropdownViewVisibility()
            }
        }
    }
    private var textFieldStackView: UIStackView!
    var networksDropdownView: UIView?
    private var presentationButton: UIButton!  // Button for presenting menu programmatically
    var onCardNetworkSelected: ((PrimerCardNetwork) -> Void)?
    var selectedCardNetwork: PrimerCardNetwork?

    override var tintColor: UIColor! {
        didSet {
            topPlaceholderLabel.textColor = tintColor
            bottomLine.backgroundColor = tintColor
        }
    }

    var placeholderText: String?
    var rightImage: UIImage? {
        didSet {
            rightImageView.isHidden = rightImage == nil
            rightImageView.image = rightImage
        }
    }
    var rightImageTintColor: UIColor? {
        didSet {
            rightImageView.tintColor = rightImageTintColor
        }
    }
    var errorText: String? {
        didSet {
            errorLabel.text = errorText ?? ""
        }
    }

    private var verticalStackView: UIStackView = UIStackView()
    private let errorLabel = UILabel()
    private let topPlaceholderLabel = UILabel()
    private let rightImageViewContainer = UIView()
    private let rightImageView = UIImageView()
    private let bottomLine = UIView()
    private var theme: PrimerThemeProtocol = DependencyContainer.resolve()

    // References to image views inside the dropdown
    private var networkIconImageView: UIImageView?
    private var chevronImageView: UIImageView?

    // MARK: - Setup Methods

    func setup() {
        setupVerticalStackView()
        setupTopPlaceholderLabel()
        setupTextFieldStackView()
        setupBottomLine()
        setupErrorLabel()
        constrainVerticalStackView()
    }

    private func setupVerticalStackView() {
        addSubview(verticalStackView)
        verticalStackView.alignment = .fill
        verticalStackView.axis = .vertical
    }

    private func setupTopPlaceholderLabel() {
        topPlaceholderLabel.font = UIFont.systemFont(ofSize: 10.0, weight: .medium)
        topPlaceholderLabel.text = placeholderText
        topPlaceholderLabel.textColor = theme.text.system.color
        verticalStackView.addArrangedSubview(topPlaceholderLabel)
    }

    private func setupTextFieldStackView() {
        textFieldStackView = UIStackView()
        textFieldStackView.alignment = .fill
        textFieldStackView.axis = .horizontal
        textFieldStackView.spacing = 6

        // Add the fieldView
        textFieldStackView.addArrangedSubview(fieldView)
        fieldView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        fieldView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        setupRightImageViewContainer(in: textFieldStackView)
        verticalStackView.addArrangedSubview(textFieldStackView)
    }

    private func setupNetworksDropdownView() {
        guard networksDropdownView == nil else { return }

        let dropdownView = createDropdownView()
        let iconAndChevronStack = createIconAndChevronStack()

        dropdownView.addSubview(iconAndChevronStack)
        activateConstraints(for: iconAndChevronStack, in: dropdownView)

        setupPresentationButton(in: dropdownView)

        networksDropdownView = dropdownView
        textFieldStackView.addArrangedSubview(dropdownView)
        setDropdownViewConstraints(dropdownView)
    }

    // MARK: - Helper Methods

    private func createDropdownView() -> UIView {
        let dropdownView = UIView()
        dropdownView.isUserInteractionEnabled = true
        return dropdownView
    }

    private func createIconAndChevronStack() -> UIStackView {
        let iconAndChevronStack = UIStackView()
        iconAndChevronStack.axis = .horizontal
        iconAndChevronStack.alignment = .center
        iconAndChevronStack.spacing = 4

        let networkIconImageView = UIImageView(image: cardNetworks.first?.network.icon)
        self.networkIconImageView = networkIconImageView
        networkIconImageView.contentMode = .scaleAspectFit
        iconAndChevronStack.addArrangedSubview(networkIconImageView)

        let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.down", withConfiguration: UIImage.SymbolConfiguration(scale: .small)))
        self.chevronImageView = chevronImageView
        chevronImageView.contentMode = .scaleAspectFit
        iconAndChevronStack.addArrangedSubview(chevronImageView)

        return iconAndChevronStack
    }

    private func activateConstraints(for stackView: UIStackView, in containerView: UIView) {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
    }

    private func setupPresentationButton(in dropdownView: UIView) {
        presentationButton = UIButton(type: .system)
        presentationButton.alpha = 0.1
        presentationButton.translatesAutoresizingMaskIntoConstraints = false

        if #available(iOS 15.0, *) {
            setupUIMenuForButton()
        } else {
            presentationButton.addTarget(self, action: #selector(showCardNetworkSelectionAlert), for: .touchUpInside)
        }

        dropdownView.addSubview(presentationButton)
    }

    @available(iOS 15.0, *)
    private func setupUIMenuForButton() {
        let uiActions = cardNetworks.map { network in
            UIAction(title: network.displayName, image: network.network.icon) { _ in
                self.selectedCardNetwork = network
                self.networkIconImageView?.image = network.network.icon
                self.onCardNetworkSelected?(network)
            }
        }

        let menu = UIMenu(options: .singleSelection, children: uiActions)
        presentationButton.menu = menu
        presentationButton.showsMenuAsPrimaryAction = true
    }

    private func setDropdownViewConstraints(_ dropdownView: UIView) {
        dropdownView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dropdownView.widthAnchor.constraint(equalToConstant: 44),
            dropdownView.heightAnchor.constraint(equalToConstant: 36),
            presentationButton.widthAnchor.constraint(equalToConstant: 44),
            presentationButton.heightAnchor.constraint(equalToConstant: 36)
        ])
        dropdownView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        dropdownView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }

    private func updateNetworksDropdownViewVisibility() {
        if cardNetworks.count > 1 {
            if networksDropdownView == nil {
                setupNetworksDropdownView()
            }
            networksDropdownView?.isHidden = false
            rightImageViewContainer.isHidden = true
        } else {
            networksDropdownView?.isHidden = true
            rightImageViewContainer.isHidden = false
        }
    }

    private func setupRightImageViewContainer(in stackView: UIStackView) {
        rightImageView.contentMode = .scaleAspectFit

        stackView.addArrangedSubview(rightImageViewContainer)
        rightImageViewContainer.translatesAutoresizingMaskIntoConstraints = false
        rightImageViewContainer.addSubview(rightImageView)
        rightImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rightImageView.topAnchor.constraint(equalTo: rightImageViewContainer.topAnchor, constant: 6),
            rightImageView.bottomAnchor.constraint(equalTo: rightImageViewContainer.bottomAnchor, constant: -6),
            rightImageView.leadingAnchor.constraint(equalTo: rightImageViewContainer.leadingAnchor),
            rightImageView.trailingAnchor.constraint(equalTo: rightImageViewContainer.trailingAnchor),
            rightImageView.widthAnchor.constraint(equalTo: rightImageViewContainer.heightAnchor)
        ])
    }

    private func setupBottomLine() {
        bottomLine.backgroundColor = theme.colors.primary
        bottomLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        verticalStackView.addArrangedSubview(bottomLine)
    }

    private func setupErrorLabel() {
        errorLabel.textColor = theme.text.error.color
        errorLabel.heightAnchor.constraint(equalToConstant: 12.0).isActive = true
        errorLabel.font = UIFont.systemFont(ofSize: 10.0, weight: .medium)
        errorLabel.text = nil
        verticalStackView.addArrangedSubview(errorLabel)
    }

    private func constrainVerticalStackView() {
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            verticalStackView.topAnchor.constraint(equalTo: topAnchor),
            verticalStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            verticalStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            verticalStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Dropdown Actions

    @objc private func showCardNetworkSelectionAlert() {
        // Use UIAlertController for earlier iOS versions
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        // Create UIAlertAction for each network and add to the alert
        cardNetworks.forEach { network in
            let action = UIAlertAction(title: network.displayName, style: .default) { _ in
                self.selectedCardNetwork = network
                self.networkIconImageView?.image = network.network.icon
                self.onCardNetworkSelected?(network)
            }
            action.setValue(network.network.icon?.withRenderingMode(.alwaysOriginal), forKey: "image")
            alertController.addAction(action)
        }

        // Present the alert controller
        if let viewController = UIApplication.shared.keyWindow?.rootViewController {
            viewController.present(alertController, animated: true)
        }
    }
}

fileprivate extension UIApplication {
    var windows: [UIWindow] {
        let windowScene = self.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        guard let windows = windowScene?.windows else {
            return []
        }
        return windows
    }

    var keyWindow: UIWindow? {
        return windows.first(where: { $0.isKeyWindow })
    }
}
