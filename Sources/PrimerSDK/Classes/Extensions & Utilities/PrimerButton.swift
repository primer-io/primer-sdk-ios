//
//  UIButtonExtension.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 18/3/21.
//

#if canImport(UIKit)

import UIKit

internal class PrimerButton: UIButton {

    func setBusy(theme: PrimerThemeProtocol) {
        let indicator = UIActivityIndicatorView()
        self.setTitle("", for: .normal)
        self.addSubview(indicator)

        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.topAnchor.constraint(equalTo: topAnchor).isActive = true
        indicator.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        indicator.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        indicator.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        indicator.color = theme.colorTheme.text2
        indicator.startAnimating()
    }

    func showSpinner(_ color: UIColor = .white) {
        self.isUserInteractionEnabled = false
        self.setTitle("", for: .normal)
        let newSpinner = UIActivityIndicatorView()
        newSpinner.color = color
        self.addSubview(newSpinner)
        newSpinner.translatesAutoresizingMaskIntoConstraints = false
        newSpinner.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        newSpinner.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        newSpinner.widthAnchor.constraint(equalToConstant: 20).isActive = true
        newSpinner.heightAnchor.constraint(equalToConstant: 20).isActive = true
        newSpinner.startAnimating()
    }

    func hideSpinner(_ title: String, spinner: UIActivityIndicatorView) {
        spinner.removeFromSuperview()
        self.setTitle(title, for: .normal)
    }

    func toggleValidity(_ isValid: Bool, validColor: UIColor, defaultColor: UIColor) {
        self.backgroundColor = isValid ? validColor : defaultColor
        self.isEnabled = isValid
    }

}

#endif
