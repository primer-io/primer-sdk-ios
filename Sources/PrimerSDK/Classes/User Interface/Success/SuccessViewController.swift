//
//  SuccessViewController.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 13/01/2021.
//

#if canImport(UIKit)

import UIKit

class SuccessViewController: UIViewController {
    
    var screenType: SuccessScreenType?
    
    let navBar = UINavigationBar()
    let icon = UIImageView(image: ImageName.success.image?.withRenderingMode(.alwaysTemplate))
    let message = UILabel()
    let confirmationMessage = UILabel()
    let referenceTitle = UILabel()
    let reference = UILabel()
    
    @Dependency private(set) var viewModel: SuccessScreenViewModelProtocol
    @Dependency private(set) var theme: PrimerThemeProtocol
    
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
extension SuccessViewController {
    func configureNavbar() {
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
        message.text = viewModel.getTitle(screenType)
        message.numberOfLines = 0
        message.textAlignment = .center
        message.textColor = theme.colorTheme.text1
        message.font = .systemFont(ofSize: 20)
    }
    
    func configureConfirmationMessage() {
        confirmationMessage.text = viewModel.getConfirmationMessage(screenType)
        confirmationMessage.numberOfLines = 0
        confirmationMessage.font = .systemFont(ofSize: 13)
        confirmationMessage.textAlignment = .center
    }
    
    func configureReferenceTitle() {
        if (screenType != .directDebit) { return }
        referenceTitle.text = "Reference".uppercased()
        referenceTitle.textColor = theme.colorTheme.neutral1
        referenceTitle.font = .systemFont(ofSize: 13)
    }
    
    func configureReference() {
        reference.text = viewModel.getReference(screenType)
        reference.font = .systemFont(ofSize: 17)
    }
}

// MARK: Constraints
extension SuccessViewController {
    func anchorIcon() {
        icon.tintColor = theme.colorTheme.success1
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        icon.bottomAnchor.constraint(equalTo: message.topAnchor, constant: -18).isActive = true
    }
    
    func anchorMessage() {
        message.translatesAutoresizingMaskIntoConstraints = false
        message.topAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        message.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        message.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: theme.layout.safeMargin + 12).isActive = true
        message.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -(theme.layout.safeMargin + 12)).isActive = true
    }
    
    func anchorConfirmationMessage() {
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

class SuccessScreenViewModel: SuccessScreenViewModelProtocol {
    
    var mandate: DirectDebitMandate {
        return state.directDebitMandate
    }
    
    func getMandateId(_ screenType: SuccessScreenType?) -> String {
        return state.mandateId ?? ""
    }
    
    @Dependency private(set) var state: AppStateProtocol
    
    func getTitle(_ screenType: SuccessScreenType?) -> String {
        switch screenType {
        case .directDebit:
            return "Direct debit set up \nsuccessfully".localized()
        default:
            return "Payment method successfully added to your account".localized()
        }
    }
    
    func getConfirmationMessage(_ screenType: SuccessScreenType?) -> String {
        switch screenType {
        case .directDebit:
            guard let name = state.settings.businessDetails?.name else { return "" }
            return name + " " + "will appear on your bank statement when payments are taken against the Direct Debit."
        default:
            return ""
        }
    }
    
    func getReference(_ screenType: SuccessScreenType?) -> String {
        return getMandateId(screenType).uppercased()
    }
}

#endif
