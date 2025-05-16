//
//  ACHMandateViewController.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 03.07.2024.
//

import UIKit
import SwiftUI

final class ACHMandateViewController: PrimerViewController {

    // MARK: - Properties
    private(set) var mandateView: ACHMandateView?
    private(set) var mandateData: PrimerStripeOptions.MandateData
    private(set) var mandateViewModel: ACHMandateViewModel
    weak var delegate: ACHMandateDelegate?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(delegate: ACHMandateDelegate, mandateData: PrimerStripeOptions.MandateData) {
        self.mandateData = mandateData
        self.delegate = delegate
        self.mandateViewModel = ACHMandateViewModel(mandateData: mandateData)
        super.init(nibName: nil, bundle: nil)
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
