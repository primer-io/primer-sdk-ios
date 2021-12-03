//
//  UIButtonExtension.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 18/3/21.
//

#if canImport(UIKit)

import UIKit

///
/// Reserve the name for all primer buttons. If you need to extend UIButton, extend and use this one instead, so we
/// don't expose unnecessary functionality.
///
internal class PrimerButton: UIButton {
    var id: String?
}

internal class PrimerOldButton: PrimerButton {
    
    var spinner: UIActivityIndicatorView!
    var titleCopy: String?

    func toggleValidity(_ isValid: Bool, validColor: UIColor, defaultColor: UIColor) {
        self.backgroundColor = isValid ? validColor : defaultColor
        self.isEnabled = isValid
    }
    
    func showSpinner(_ flag: Bool, color: UIColor = .white) {
        DispatchQueue.main.async {
            if self.titleCopy == nil {
                self.titleCopy = self.titleLabel?.text
            }
            
            self.isUserInteractionEnabled = !flag
            
            if self.spinner == nil {
                self.spinner = UIActivityIndicatorView()
                self.addSubview(self.spinner)
                self.spinner.translatesAutoresizingMaskIntoConstraints = false
                self.spinner.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
                self.spinner.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
                self.spinner.widthAnchor.constraint(equalToConstant: 20).isActive = true
                self.spinner.heightAnchor.constraint(equalToConstant: 20).isActive = true
            }
            
            self.spinner.color = color
            
            flag ? self.spinner.startAnimating() : self.spinner.stopAnimating()
            flag ? self.setTitle(nil, for: .normal) : self.setTitle(self.titleCopy, for: .normal)
            self.spinner.isHidden = !flag
        }
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
