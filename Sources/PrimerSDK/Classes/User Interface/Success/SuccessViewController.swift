//
//  SuccessViewController.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 13/01/2021.
//

#if canImport(UIKit)

import UIKit

internal class SuccessViewController: PrimerViewController {

    var screenType: SuccessScreenType?

    let navBar = UINavigationBar()
    let icon = UIImageView(image: ImageName.success.image?.withRenderingMode(.alwaysTemplate))
    let message = UILabel()
    let confirmationMessage = UILabel()
    let referenceTitle = UILabel()
    let reference = UILabel()

    override func viewDidLoad() {
        view.addSubview(navBar)
        view.addSubview(icon)
        view.addSubview(message)
        view.addSubview(confirmationMessage)
        view.addSubview(referenceTitle)
        view.addSubview(reference)

        configureNavbar()
        configureIcon()
        configureMessage()
        configureConfirmationMessage()
        configureReferenceTitle()
        configureReference()

        anchorIcon()
        anchorMessage()
        anchorConfirmationMessage()
        anchorReferenceTitle()
        anchorReferenceLabel()
    }

    @objc func close() {
        dismiss(animated: true, completion: nil)
    }

}

// MARK: Configuration
internal extension SuccessViewController {
    func configureNavbar() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        let navItem = UINavigationItem()
        let backItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))
        backItem.tintColor = theme.colorTheme.success1
        navItem.leftBarButtonItem = backItem
        navBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navBar.shadowImage = UIImage()
        navBar.setItems([navItem], animated: false)
//        navBar.topItem?.title = theme.content.confirmMandateContent.topTitleText
        navBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: theme.colorTheme.text1]
        navBar.translatesAutoresizingMaskIntoConstraints = false

        if #available(iOS 13.0, *) {
            navBar.topAnchor.constraint(equalTo: view.topAnchor, constant: 6).isActive = true
        } else {
            navBar.topAnchor.constraint(equalTo: view.topAnchor, constant: 18).isActive = true
        }

        navBar.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
    }

    func configureIcon() {

    }

    func configureMessage() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        let viewModel: SuccessScreenViewModelProtocol = DependencyContainer.resolve()
        
        message.accessibilityIdentifier = "success_screen_message_label"
        message.text = viewModel.getTitle(screenType)
        message.numberOfLines = 0
        message.textAlignment = .center
        message.textColor = theme.colorTheme.text1
        message.font = theme.fontTheme.successMessageFont
    }

    func configureConfirmationMessage() {
        let viewModel: SuccessScreenViewModelProtocol = DependencyContainer.resolve()
        confirmationMessage.text = viewModel.getConfirmationMessage(screenType)
        confirmationMessage.numberOfLines = 0
        confirmationMessage.font = .systemFont(ofSize: 13)
        confirmationMessage.textAlignment = .center
    }

    func configureReferenceTitle() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        if screenType != .directDebit { return }
        referenceTitle.text = "Reference".uppercased()
        referenceTitle.textColor = theme.colorTheme.neutral1
        referenceTitle.font = .systemFont(ofSize: 13)
    }

    func configureReference() {
        let viewModel: SuccessScreenViewModelProtocol = DependencyContainer.resolve()
        reference.text = viewModel.getReference(screenType)
        reference.font = .systemFont(ofSize: 17)
    }
}

// MARK: Constraints
internal extension SuccessViewController {
    func anchorIcon() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        icon.tintColor = theme.colorTheme.success1
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        icon.bottomAnchor.constraint(equalTo: message.topAnchor, constant: -18).isActive = true
    }

    func anchorMessage() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        message.translatesAutoresizingMaskIntoConstraints = false
        message.topAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        message.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        message.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: theme.layout.safeMargin + 12).isActive = true
        message.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -(theme.layout.safeMargin + 12)).isActive = true
    }

    func anchorConfirmationMessage() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        confirmationMessage.translatesAutoresizingMaskIntoConstraints = false
        confirmationMessage.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        confirmationMessage.topAnchor.constraint(equalTo: message.bottomAnchor, constant: 24).isActive = true
        confirmationMessage.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: theme.layout.safeMargin + 12).isActive = true
        confirmationMessage.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -(theme.layout.safeMargin + 12)).isActive = true
    }

    func anchorReferenceTitle() {
        referenceTitle.translatesAutoresizingMaskIntoConstraints = false
        referenceTitle.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        referenceTitle.topAnchor.constraint(equalTo: confirmationMessage.bottomAnchor, constant: 24).isActive = true
    }

    func anchorReferenceLabel() {
        reference.translatesAutoresizingMaskIntoConstraints = false
        reference.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        reference.topAnchor.constraint(equalTo: referenceTitle.bottomAnchor, constant: 6).isActive = true
    }
}

enum SuccessScreenType {
    case regular
    case directDebit
}

protocol SuccessScreenViewModelProtocol: class {
    var mandate: DirectDebitMandate { get }
    func getMandateId(_ screenType: SuccessScreenType?) -> String
    func getTitle(_ screenType: SuccessScreenType?) -> String
    func getConfirmationMessage(_ screenType: SuccessScreenType?) -> String
    func getReference(_ screenType: SuccessScreenType?) -> String
}

internal class SuccessScreenViewModel: SuccessScreenViewModelProtocol {

    var mandate: DirectDebitMandate {
        let state: AppStateProtocol = DependencyContainer.resolve()
        return state.directDebitMandate
    }
        
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func getMandateId(_ screenType: SuccessScreenType?) -> String {
        let state: AppStateProtocol = DependencyContainer.resolve()
        return state.mandateId ?? ""
    }

    func getTitle(_ screenType: SuccessScreenType?) -> String {
        switch screenType {
        case .directDebit:
            return NSLocalizedString("primer-success-screen-direct-debit-setup-success",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Direct debit set up \nsuccessfully",
                                     comment: "Direct debit set up \nsuccessfully - Success Screen Title (Direct Debit)")

        default:
            if Primer.shared.flow.internalSessionFlow.vaulted {
                return NSLocalizedString("primer-success-screen-vault-setup-success",
                                         tableName: nil,
                                         bundle: Bundle.primerResources,
                                         value: "A new payment method\nhas been successfully added!",
                                         comment: "A new payment method\nhas been successfully added! - Success Screen Title")
            } else {
                return NSLocalizedString("primer-success-screen-setup-success",
                                         tableName: nil,
                                         bundle: Bundle.primerResources,
                                         value: "Success!",
                                         comment: "Success! - Success Screen Title")
            }
        }
    }

    func getConfirmationMessage(_ screenType: SuccessScreenType?) -> String {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        switch screenType {
        case .directDebit:
            guard let name = settings.businessDetails?.name else { return "" }
            return name + " " + NSLocalizedString("primer-success-screen-confirmation-message",
                                                  tableName: nil,
                                                  bundle: Bundle.primerResources,
                                                  value: "will appear on your bank statement when payments are taken against the Direct Debit.",
                                                  comment: "@payment_method_name will appear on your bank statement when payments are taken against the Direct Debit. - Success Screen Confirmation Message")
        default:
            return ""
        }
    }

    func getReference(_ screenType: SuccessScreenType?) -> String {
        return getMandateId(screenType).uppercased()
    }
}

#endif
