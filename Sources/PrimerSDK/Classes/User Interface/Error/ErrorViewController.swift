//
//  ErrorViewController.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 13/01/2021.
//

#if canImport(UIKit)

import UIKit

class ErrorViewController: UIViewController {
    
    let navBar = UINavigationBar()
    let icon = UIImageView(image: ImageName.error.image?.withRenderingMode(.alwaysTemplate))
    let message = UILabel()
    
    @Dependency private(set) var theme: PrimerThemeProtocol
    
    init(message: String) {
        super.init(nibName: nil, bundle: nil)
        self.message.text = message
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        
        view.addSubview(navBar)
        view.addSubview(icon)
        view.addSubview(message)
        
        configureNavbar()
        configureMessage()
        
        anchorIcon()
        anchorMessage()
        
    }
    
    @objc func close() {
        dismiss(animated: true, completion: nil)
    }
    
}

extension ErrorViewController {
    
    func configureNavbar() {
        let navItem = UINavigationItem()
        let backItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))
        backItem.tintColor = theme.colorTheme.tint1
        navItem.leftBarButtonItem = backItem
        navBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navBar.shadowImage = UIImage()
        navBar.setItems([navItem], animated: false)
        navBar.topItem?.title = "Error!"
        navBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: theme.colorTheme.text1]
        navBar.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 13.0, *) {
            navBar.topAnchor.constraint(equalTo: view.topAnchor, constant: 6).isActive = true
        } else {
            navBar.topAnchor.constraint(equalTo: view.topAnchor, constant: 18).isActive = true
        }
        
        navBar.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
    }
    
    func configureMessage() {
        if (!message.text.exists) {
            message.text = "Error, please close checkout and retry!"
        }
        message.numberOfLines = 0
        message.textAlignment = .center
        message.font = .systemFont(ofSize: 20)
    }
}

extension ErrorViewController {
    
    func anchorIcon() {
        icon.tintColor = theme.colorTheme.error1
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        icon.widthAnchor.constraint(equalToConstant: 56).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 56).isActive = true
        icon.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 24).isActive = true
    }
    
    func anchorMessage() {
        message.translatesAutoresizingMaskIntoConstraints = false
        message.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 36).isActive = true
        message.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        message.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: theme.layout.safeMargin + 12).isActive = true
        message.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -(theme.layout.safeMargin + 12)).isActive = true
    }
    
}

#endif
