//
//  LoadingViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 2/7/21.
//

#if canImport(UIKit)

import UIKit

internal class LoadingViewController: PrimerViewController {
    
    let indicator = UIActivityIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        indicator.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        indicator.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        indicator.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        indicator.startAnimating()
    }
    
}

#endif
