//
//  PrimerFormViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 27/7/21.
//

import UIKit

class PrimerFormViewController: UIViewController {

    internal var verticalStackView: UIStackView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(verticalStackView)
        verticalStackView.alignment = .fill
        verticalStackView.axis = .vertical
        
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 11.0, *) {
            verticalStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        } else {
            verticalStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20).isActive = true
        }
        if #available(iOS 11.0, *) {
            verticalStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 20).isActive = true
        } else {
            verticalStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 20).isActive = true
        }
        verticalStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        verticalStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        
    }
    
}
