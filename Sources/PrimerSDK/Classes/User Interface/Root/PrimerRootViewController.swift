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

        scrollViewBottomConstraint.constant = scrollView.bounds.height
        view.layoutIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        scrollViewBottomConstraint.constant = 0.0

        UIView.animate(withDuration: 2, delay: 0.0, options: .curveEaseInOut) {
            self.view.layoutIfNeeded()
        } completion: { _ in

        }
    }
    
}

class PrimerContainerNavigationController: UINavigationController {
    
    
}

class PrimerContainerViewController: UIViewController {
    
    
}
