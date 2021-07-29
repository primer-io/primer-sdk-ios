//
//  PrimerRootViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 27/7/21.
//

import UIKit

class PrimerRootViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var childContainerView: UIView!
    @IBOutlet weak var childContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
        
    class func instantiate() -> PrimerRootViewController {
        let bundle = Bundle.primerFramework
        let storyboard = UIStoryboard(name: "Primer", bundle: bundle)
        let prvc = storyboard.instantiateViewController(withIdentifier: "PrimerRootViewController") as! PrimerRootViewController
        return prvc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.bounces = false

        // Hide scrollview at the bottom of the screen
        scrollViewBottomConstraint.constant = scrollView.bounds.height
        childContainerViewHeightConstraint.constant = 0
        view.layoutIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        scrollViewBottomConstraint.constant = 0.0
        
        let fvc = PrimerCardFormViewController(flow: .checkout)
        fvc.view.translatesAutoresizingMaskIntoConstraints = false
        fvc.view.widthAnchor.constraint(equalToConstant: scrollView.frame.width).isActive = true
        fvc.view.layoutIfNeeded()
        
        addChild(fvc)
        childContainerView.addSubview(fvc.view)
        
        fvc.didMove(toParent: self)
        
        childContainerViewHeightConstraint.constant = fvc.view.frame.height
        
        UIView.animate(withDuration: 0.3, delay: 1, options: .curveEaseInOut) {
            self.view.layoutIfNeeded()
        } completion: { _ in

        }
    }
    
    func switchFlow(_ flow: PrimerInternalSessionFlow) {
        switch flow {
        case .checkout:
            break
        case .checkoutWithCard:
            break
        default:
            break
        }
    }
    
}

class PrimerContainerNavigationController: UINavigationController {
    
    
}

class PrimerContainerViewController: UIViewController {
    
    
}
