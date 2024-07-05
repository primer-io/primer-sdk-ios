//
//  ACHMandateViewController.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 03.07.2024.
//

import UIKit
import SwiftUI

class ACHMandateViewController: UIViewController {

    // MARK: - Properties
    var mandateView: ACHMandateView?
    var mandateViewModel: ACHMandateViewModel = ACHMandateViewModel()
    var mandateData: PrimerStripeOptions.MandateData
    weak var delegate: ACHMandateDelegate?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(delegate: ACHMandateDelegate, mandateData: PrimerStripeOptions.MandateData) {
        self.mandateData = mandateData
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        addMandateView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let parentVC = self.parent as? PrimerContainerViewController {
            parentVC.mockedNavigationBar.hidesBackButton = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let parentVC = self.parent as? PrimerContainerViewController {
            parentVC.mockedNavigationBar.hidesBackButton = false
        }
    }
    
    private func addMandateView() {
        let mandateText = mandateViewModel.getMandateText(for: mandateData)
        mandateView = ACHMandateView(mandateText: mandateText, onAcceptPressed: {
            self.delegate?.mandateAccepted()
        }, onCancelPressed: {
            self.delegate?.mandateDeclined()
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
