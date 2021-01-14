//
//  ConfirmMandateViewController.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 10/01/2021.
//

import UIKit

class ConfirmMandateViewController: UIViewController {
    
    var fromView: ConfirmMandateView?
    
    let viewModel: ConfirmMandateViewModelProtocol
    let transitionDelegate = TransitionDelegate()
    
    var iban: String?
    
    init(viewModel: ConfirmMandateViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = transitionDelegate
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    }
    
}

class ConfirmMandateView: UIView {
    
}

protocol ConfirmMandateViewModelProtocol {
    
}

class ConfirmMandateViewModel: ConfirmMandateViewModelProtocol {
    
}
