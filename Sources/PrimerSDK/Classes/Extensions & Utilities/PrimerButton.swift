//
//  UIButtonExtension.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 18/3/21.
//

#if canImport(UIKit)

import UIKit

internal class PrimerButton: UIButton {

    var spinner: UIActivityIndicatorView!
    var titleCopy: String?

    func toggleValidity(_ isValid: Bool, validColor: UIColor, defaultColor: UIColor) {
        self.backgroundColor = isValid ? validColor : defaultColor
        self.isEnabled = isValid
    }
    
    func showSpinner(_ flag: Bool, color: UIColor = .white) {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        if titleCopy == nil {
            titleCopy = titleLabel?.text
        }
        
        isUserInteractionEnabled = !flag
        
        if spinner == nil {
            spinner = UIActivityIndicatorView()
            addSubview(spinner)
            spinner.translatesAutoresizingMaskIntoConstraints = false
            spinner.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
            spinner.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
            spinner.widthAnchor.constraint(equalToConstant: 20).isActive = true
            spinner.heightAnchor.constraint(equalToConstant: 20).isActive = true
        }
        
        spinner.color = theme.mainButton.text.color
        
        flag ? spinner.startAnimating() : spinner.stopAnimating()
        flag ? setTitle(nil, for: .normal) : setTitle(titleCopy, for: .normal)
        spinner.isHidden = !flag
    }

    func pin(
        to view: UIView,
        leading: CGFloat = 0,
        top: CGFloat = 0,
        trailing: CGFloat = 0,
        bottom: CGFloat = 0
    ) {
        topAnchor.constraint(equalTo: view.topAnchor, constant: top).isActive = true
        bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: bottom).isActive = true
        leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: leading).isActive = true
        trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: trailing).isActive = true
    }

}

#endif
