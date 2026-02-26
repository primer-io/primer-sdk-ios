//
//  PrimerLoadingViewController.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import UIKit

/// PrimerLoadingViewController is a loading view controller, with variable height.
final class PrimerLoadingViewController: PrimerViewController {

    private var height: CGFloat
    private(set) var imageView: UIImageView?
    private(set) var message: String?
    private(set) var activityIndicatorView: UIActivityIndicatorView = UIActivityIndicatorView()
    private(set) var resultView: PrimerResultComponentView!

    init(height: CGFloat, imageView: UIImageView?, message: String?) {
        self.height = height
        self.imageView = imageView
        self.message = message
        super.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        postUIEvent(.view, type: .view, in: .sdkLoading)
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        view.backgroundColor = theme.view.backgroundColor

        view.heightAnchor.constraint(equalToConstant: height).isActive = true

        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        activityIndicatorView.widthAnchor.constraint(equalToConstant: 50.0).isActive = true
        activityIndicatorView.accessibilityIdentifier = "Loading Indicator"
        activityIndicatorView.startAnimating()

        resultView = PrimerResultComponentView(frame: .zero,
                                               imageView: self.imageView,
                                               message: self.message,
                                               loadingIndicator: self.activityIndicatorView)
        view.addSubview(resultView)
        resultView.translatesAutoresizingMaskIntoConstraints = false
        resultView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        resultView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        resultView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        resultView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

}
