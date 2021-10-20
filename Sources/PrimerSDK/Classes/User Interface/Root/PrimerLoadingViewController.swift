//
//  PrimerLoadingViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 30/7/21.
//

#if canImport(UIKit)

import UIKit

/// PrimerLoadingViewController is a loading view controller, with variable height.
class PrimerLoadingViewController: PrimerViewController {
    
    private var activityIndicatorView: UIActivityIndicatorView = UIActivityIndicatorView()
    private var height: CGFloat
    
    init(withHeight height: CGFloat) {
        self.height = height
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        view.backgroundColor = theme.colorTheme.main1
        
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
        
        view.addSubview(activityIndicatorView)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        activityIndicatorView.widthAnchor.constraint(equalToConstant: 50.0).isActive = true
        activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        activityIndicatorView.startAnimating()
    }
    
}

#endif
