//
//  PrimerCustomTextField.swift
//  PrimerSDK
//
//  Created by Boris on 25.3.24..
//

import UIKit

class PrimerCustomFieldView: UIView {

    // MARK: - Properties

    // Custom text field view for input
    var fieldView: PrimerTextFieldView!

    // Array of supported card networks, updating the dropdown view visibility on change
    var cardNetworks: [PrimerCardNetwork] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.updateNetworksDropdownViewVisibility()
            }
        }
    }

    private var textFieldStackView: UIStackView!  // Stack view containing the text field and dropdown
    var networksDropdownView: UIView?  // Dropdown view for displaying available card networks
    private var presentationButton: UIButton!  // Button used to trigger menu programmatically

    // Callback triggered when a card network is selected
    var onCardNetworkSelected: ((PrimerCardNetwork) -> Void)?
    var selectedCardNetwork: PrimerCardNetwork?

    override var tintColor: UIColor! {  // Updates label and line color on tint change
        didSet {
            topPlaceholderLabel.textColor = tintColor
            bottomLine.backgroundColor = tintColor
        }
    }

    // Placeholder text for the top label
    var placeholderText: String?

    // Image on the right side of the text field
    var rightImage: UIImage? {
        didSet {
            rightImageView.isHidden = rightImage == nil
            rightImageView.image = rightImage
        }
    }

    // Tint color for the right image
    var rightImageTintColor: UIColor? {
        didSet {
            rightImageView.tintColor = rightImageTintColor
        }
    }

    // Error text displayed below the text field
    var errorText: String? {
        didSet {
            errorLabel.text = errorText ?? ""
        }
    }

    private var verticalStackView: UIStackView = UIStackView()  // Main vertical stack view for layout
    private let errorLabel = UILabel()  // Label to display error messages
    private let topPlaceholderLabel = UILabel()  // Label for the placeholder text
    private let rightImageViewContainer = UIView()  // Container for right-side image view
    private let rightImageView = UIImageView()  // Right image view
    private let bottomLine = UIView()  // Line below the text field
    private var theme: PrimerThemeProtocol = DependencyContainer.resolve()  // Theme for styling

    // References for icon and chevron image views in the dropdown
    private var networkIconImageView: UIImageView?
    private var chevronImageView: UIImageView?

    // MARK: - Setup Methods

    // Sets up the view hierarchy and layout
    func setup() {
        setupVerticalStackView()
        setupTopPlaceholderLabel()
        setupTextFieldStackView()
        setupBottomLine()
        setupErrorLabel()
        constrainVerticalStackView()
    }

    // Sets up the main vertical stack view
    private func setupVerticalStackView() {
        addSubview(verticalStackView)
        verticalStackView.alignment = .fill
        verticalStackView.axis = .vertical
    }

    // Configures the top label for the placeholder text
    private func setupTopPlaceholderLabel() {
        topPlaceholderLabel.font = UIFont.systemFont(ofSize: 10.0, weight: .medium)
        topPlaceholderLabel.text = placeholderText
        topPlaceholderLabel.textColor = theme.text.system.color
        verticalStackView.addArrangedSubview(topPlaceholderLabel)
    }

    // Configures the text field stack view with the field view and right image view
    private func setupTextFieldStackView() {
        textFieldStackView = UIStackView()
        textFieldStackView.alignment = .fill
        textFieldStackView.axis = .horizontal
        textFieldStackView.spacing = 6

        // Add the text field to the stack view
        textFieldStackView.addArrangedSubview(fieldView)
        fieldView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        fieldView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // Adds the right image view container to the stack view
        setupRightImageViewContainer(in: textFieldStackView)
        verticalStackView.addArrangedSubview(textFieldStackView)
    }

    // Configures the dropdown view to display available card networks
    private func setupNetworksDropdownView() {
        guard networksDropdownView == nil else { return }

        let dropdownView = createDropdownView()
        let iconAndChevronStack = createIconAndChevronStack()

        // Add stack containing the icon and chevron to the dropdown view
        dropdownView.addSubview(iconAndChevronStack)
        activateConstraints(for: iconAndChevronStack, in: dropdownView)

        // Sets up the hidden button used to present the dropdown options
        setupPresentationButton(in: dropdownView)

        networksDropdownView = dropdownView
        textFieldStackView.addArrangedSubview(dropdownView)
        setDropdownViewConstraints(dropdownView)
    }

    // MARK: - Helper Methods

    // Creates the dropdown view container
    private func createDropdownView() -> UIView {
        let dropdownView = UIView()
        dropdownView.isUserInteractionEnabled = true
        return dropdownView
    }

    // Creates a horizontal stack view with the network icon and chevron for the dropdown
    private func createIconAndChevronStack() -> UIStackView {
        let iconAndChevronStack = UIStackView()
        iconAndChevronStack.axis = .horizontal
        iconAndChevronStack.alignment = .center
        iconAndChevronStack.spacing = 4

        // Creates and adds the network icon
        let networkIconImageView = UIImageView(image: cardNetworks.first?.network.icon)
        self.networkIconImageView = networkIconImageView
        networkIconImageView.contentMode = .scaleAspectFit
        iconAndChevronStack.addArrangedSubview(networkIconImageView)

        // Creates and adds the chevron icon
        let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.down", withConfiguration: UIImage.SymbolConfiguration(scale: .small)))
        self.chevronImageView = chevronImageView
        chevronImageView.contentMode = .scaleAspectFit
        iconAndChevronStack.addArrangedSubview(chevronImageView)

        return iconAndChevronStack
    }

    // Activates constraints to pin the stack view within its container
    private func activateConstraints(for stackView: UIStackView, in containerView: UIView) {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
    }

    // Configures the presentation button for triggering the dropdown options
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

    // Configures the UIMenu for iOS 15 and above
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

    // Sets constraints for the dropdown view and presentation button
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

    // Updates dropdown visibility based on the number of card networks
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

    // Configures the right image view container in the text field stack view
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

    // Configures the bottom line beneath the text field
    private func setupBottomLine() {
        bottomLine.backgroundColor = theme.colors.primary
        bottomLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        verticalStackView.addArrangedSubview(bottomLine)
    }

    // Configures the error label below the text field
    private func setupErrorLabel() {
        errorLabel.textColor = theme.text.error.color
        errorLabel.heightAnchor.constraint(equalToConstant: 12.0).isActive = true
        errorLabel.font = UIFont.systemFont(ofSize: 10.0, weight: .medium)
        errorLabel.text = nil
        verticalStackView.addArrangedSubview(errorLabel)
    }

    // Sets up constraints for the main vertical stack view
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

    // Shows an alert for selecting a card network (for iOS < 15)
    @objc private func showCardNetworkSelectionAlert() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        cardNetworks.forEach { network in
            let action = UIAlertAction(title: network.displayName, style: .default) { _ in
                self.selectedCardNetwork = network
                self.networkIconImageView?.image = network.network.icon
                self.onCardNetworkSelected?(network)
            }
            action.setValue(network.network.icon?.withRenderingMode(.alwaysOriginal), forKey: "image")
            alertController.addAction(action)
        }

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
