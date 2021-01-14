//
//  ErrorViewController.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 13/01/2021.
//

import UIKit

class ErrorViewController: UIViewController {
    
    let message = UILabel()
    
    override func viewDidLoad() {
        
        view.addSubview(message)
        
        configureMessage()
        
        anchorMessage()
        
    }
    
}

extension ErrorViewController {
    func configureMessage() {
        message.text = "Error, please close checkout and retry!"
    }
}

extension ErrorViewController {
    
    func anchorMessage() {
        message.translatesAutoresizingMaskIntoConstraints = false
        message.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        message.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
    
}
