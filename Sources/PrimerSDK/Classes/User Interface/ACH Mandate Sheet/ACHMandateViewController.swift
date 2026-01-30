//
//  ACHMandateViewController.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerCore
import SwiftUI
import UIKit

final class ACHMandateViewController: PrimerViewController {

    // MARK: - Properties
    private(set) var mandateView: ACHMandateView?
    private(set) var mandateData: PrimerStripeOptions.MandateData
    private(set) var mandateViewModel: ACHMandateViewModel
    private weak var delegate: ACHMandateDelegate?

    init(delegate: ACHMandateDelegate, mandateData: PrimerStripeOptions.MandateData) {
        self.mandateData = mandateData
        self.delegate = delegate
        self.mandateViewModel = ACHMandateViewModel(mandateData: mandateData)
        super.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = PrimerColors.white
        addMandateView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let parentVC = self.parent as? PrimerContainerViewController {
            parentVC.mockedNavigationBar.hidesBackButton = true
        }

        DispatchQueue.main.async {
            PrimerUIManager.primerRootViewController?.enableDismissGestures(false)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let parentVC = self.parent as? PrimerContainerViewController {
            parentVC.mockedNavigationBar.hidesBackButton = false
        }

        DispatchQueue.main.async {
            PrimerUIManager.primerRootViewController?.enableDismissGestures(true)
        }
    }

    private func addMandateView() {
        mandateView = ACHMandateView(viewModel: mandateViewModel, onAcceptPressed: {
            self.delegate?.acceptMandate()
        }, onCancelPressed: {
            self.delegate?.declineMandate()
        })

        let hostingViewController = UIHostingController(rootView: mandateView)
        hostingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(hostingViewController)
        view.addSubview(hostingViewController.view)
        hostingViewController.didMove(toParent: self)
        NSLayoutConstraint.activate([
            hostingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
