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
        print("")
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        scrollViewBottomConstraint.constant = 0.0

        UIView.animate(withDuration: 2, delay: 0.0, options: .curveEaseInOut) {
            self.view.layoutIfNeeded()
        } completion: { _ in

        }

    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

class PrimerContainerNavigationController: UINavigationController {
    
    
}

class PrimerContainerViewController: UIViewController {
    
    
}
