//
//  SuccessViewController.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 13/01/2021.
//

import UIKit

class SuccessViewController: UIViewController {
    
    let icon = UIImageView(image: ImageName.success.image)
    let message = UILabel()
    let confirmationMessage = UILabel()
    let referenceTitle = UILabel()
    let reference = UILabel()
    
    var viewModel: SuccessScreenViewModelProtocol
    
    init(viewModel: SuccessScreenViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        view.addSubview(icon)
        view.addSubview(message)
        view.addSubview(confirmationMessage)
        view.addSubview(referenceTitle)
        view.addSubview(reference)
        
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
    
}

// MARK: Configuration
extension SuccessViewController {
    func configureIcon() {
        
    }
    
    func configureMessage() {
        print("🐥🐥")
        message.text = viewModel.title
        message.numberOfLines = 0
        message.textAlignment = .center
        message.font = .systemFont(ofSize: 20)
    }
    
    func configureConfirmationMessage() {
        confirmationMessage.text = viewModel.confirmationMessage
        confirmationMessage.numberOfLines = 0
        confirmationMessage.font = .systemFont(ofSize: 13)
        confirmationMessage.textAlignment = .center
    }
    
    func configureReferenceTitle() {
        if (viewModel.successScreenType != .directDebit) { return }
        referenceTitle.text = "Reference".uppercased()
        referenceTitle.textColor = Primer.theme.colorTheme.disabled1
        referenceTitle.font = .systemFont(ofSize: 13)
    }
    
    func configureReference() {
        reference.text = viewModel.reference
        reference.font = .systemFont(ofSize: 17)
    }
}

// MARK: Constraints
extension SuccessViewController {
    func anchorIcon() {
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        icon.topAnchor.constraint(equalTo: view.topAnchor, constant: 48).isActive = true
    }
    
    func anchorMessage() {
        message.translatesAutoresizingMaskIntoConstraints = false
        message.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 24).isActive = true
        message.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
    
    func anchorConfirmationMessage() {
        confirmationMessage.translatesAutoresizingMaskIntoConstraints = false
        confirmationMessage.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        confirmationMessage.topAnchor.constraint(equalTo: message.bottomAnchor, constant: 24).isActive = true
        confirmationMessage.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Primer.theme.layout.safeMargin).isActive = true
        confirmationMessage.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Primer.theme.layout.safeMargin).isActive = true
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
    var successScreenType: SuccessScreenType { get }
    var mandate: DirectDebitMandate { get }
    var mandateId: String? { get }
    var title: String { get }
    var confirmationMessage: String { get }
    var reference: String { get }
}

class SuccessScreenViewModel: SuccessScreenViewModelProtocol {
    let successScreenType: SuccessScreenType
    
    var mandate: DirectDebitMandate {
        return state.directDebitMandate
    }
    
    var mandateId: String? {
        return state.mandateId
    }
    
    let state: AppStateProtocol
    
    init(context: CheckoutContext, type: SuccessScreenType) {
        print("🐥")
        self.state = context.state
        self.successScreenType = type
    }
    
    var title: String {
        switch successScreenType {
        case .directDebit:
            return "Direct debit set up \nsuccessfully".localized()
        default:
            return "Success!".localized()
        }
    }
    
    var confirmationMessage: String {
        switch successScreenType {
        case .directDebit:
            guard let email = mandate.email else { return "" }
            return "Company name will appear on your bank statement when payments are taken against the Direct Debit. A confirmation has been sent to \(email)"
        default:
            return ""
        }
    }
    
    var reference: String {
        switch successScreenType {
        case .directDebit:
            guard let mandateId = mandateId else { return "" }
            return mandateId.uppercased()
        default:
            return ""
        }
    }
}
