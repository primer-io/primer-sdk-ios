//
//  SuccessViewController.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 13/01/2021.
//

#if canImport(UIKit)

import UIKit

internal class SuccessViewController: PrimerViewController {

    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    var screenType: SuccessScreenType?
    
    var rightBarButton: UIButton!
    let icon = UIImageView(image: ImageName.success.image?.withRenderingMode(.alwaysTemplate))
    let message = UILabel()
    let confirmationMessage = UILabel()
    let referenceTitle = UILabel()
    let reference = UILabel()
    
    

    override func viewDidLoad() {
        view.addSubview(icon)
        view.addSubview(message)
        view.addSubview(confirmationMessage)
        view.addSubview(referenceTitle)
        view.addSubview(reference)
                
        rightBarButton = UIButton()
        rightBarButton.setTitle("Done", for: .normal)
        rightBarButton.setTitleColor(theme.colorTheme.main1, for: .normal)
        rightBarButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        icon.tintColor = theme.colorTheme.main1

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
        
        (parent as? PrimerContainerViewController)?.mockedNavigationBar.hidesBackButton = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        (parent as? PrimerContainerViewController)?.mockedNavigationBar.rightBarButton = rightBarButton
    }

    @objc func close() {
        Primer.shared.dismiss()
    }

}

// MARK: Configuration
internal extension SuccessViewController {

    func configureIcon() {
        icon.tintColor = theme.colorTheme.success1
    }

    func configureMessage() {
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
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        icon.widthAnchor.constraint(equalToConstant: 56).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 56).isActive = true
        message.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 6).isActive = true
    }

    func anchorMessage() {
        message.translatesAutoresizingMaskIntoConstraints = false
        message.topAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        message.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        message.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        message.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
    }

    func anchorConfirmationMessage() {
        confirmationMessage.translatesAutoresizingMaskIntoConstraints = false
        confirmationMessage.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        confirmationMessage.topAnchor.constraint(equalTo: message.bottomAnchor, constant: 24).isActive = true
        confirmationMessage.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        confirmationMessage.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
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
