//
//  SuccessViewController.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 13/01/2021.
//

import UIKit

class SuccessViewController: UIViewController {
    
    let icon = UIImageView(image: UIImage(named: "success"))
    let message = UILabel()
    let confirmationMessage = UILabel()
    
    override func viewDidLoad() {
        view.addSubview(icon)
        view.addSubview(message)
        view.addSubview(confirmationMessage)
        
        configureIcon()
        configureMessage()
        configureConfirmationMessage()
        
        anchorIcon()
        anchorMessage()
        anchorConfirmationMessage()
    }
    
}

extension SuccessViewController {
    func configureIcon() {
        
    }
    func configureMessage() {
        message.text = "Success"
        message.font = .systemFont(ofSize: 20)
    }
    func configureConfirmationMessage() {
        
    }
}

extension SuccessViewController {
    func anchorIcon() {
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        icon.bottomAnchor.constraint(equalTo: message.topAnchor, constant: -18).isActive = true
    }
    func anchorMessage() {
        message.translatesAutoresizingMaskIntoConstraints = false
        message.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        message.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
    func anchorConfirmationMessage() {
        confirmationMessage.translatesAutoresizingMaskIntoConstraints = false
        confirmationMessage.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        confirmationMessage.topAnchor.constraint(equalTo: message.bottomAnchor, constant: 18).isActive = true
    }
}
