//
//  PrimerRootViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 27/7/21.
//

import UIKit


    @IBOutlet weak var childContainerView: UIView!
    @IBOutlet weak var childContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var childContainerViewBottomConstraint: NSLayoutConstraint!
internal class PrimerRootViewController: PrimerViewController {
    
    private var nc: PrimerNavigationController?
    var heightConstraint: NSLayoutConstraint?
    var topPadding: CGFloat = 0.0
    var bottomPadding: CGFloat = 0.0
        
    class func instantiate() -> PrimerRootViewController {
        let bundle = Bundle.primerFramework
        let storyboard = UIStoryboard(name: "Primer", bundle: bundle)
        let prvc = storyboard.instantiateViewController(withIdentifier: "PrimerRootViewController") as! PrimerRootViewController
        return prvc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        // Hide scrollview at the bottom of the screen
        childContainerViewBottomConstraint.constant = childContainerView.bounds.height
        childContainerViewHeightConstraint.constant = 0
        view.layoutIfNeeded()
        
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows[0]
            topPadding = window.safeAreaInsets.top
            bottomPadding = window.safeAreaInsets.bottom
        } else if #available(iOS 11.0, *) {
            let window = UIApplication.shared.keyWindow
            topPadding = window?.safeAreaInsets.top ?? 0
            bottomPadding = window?.safeAreaInsets.bottom ?? 0
        } else {
            topPadding = 20.0
            bottomPadding = 0.0
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        testNavFlow()
    }
    
    func testNavFlow() {
        let cfvc = PrimerCardFormViewController(flow: .checkout)
        cfvc.view.widthAnchor.constraint(equalToConstant: self.childContainerView.frame.width).isActive = true
        show(viewController: cfvc)
        
        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
            let lvc2 = PrimerLoadingViewController(withHeight: 600)
    //        lvc.view.translatesAutoresizingMaskIntoConstraints = false
            lvc2.view.widthAnchor.constraint(equalToConstant: self.childContainerView.frame.width).isActive = true
//            lvc2.view.heightAnchor.constraint(equalToConstant: 3000).isActive = true
    //        lvc.view.layoutIfNeeded()
            self.show(viewController: lvc2)
        }
    }
    
    func show(viewController: UIViewController) {
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.layoutIfNeeded()
        
        let cvc = PrimerContainerViewController(childViewController: viewController)
        cvc.view.translatesAutoresizingMaskIntoConstraints = false
        cvc.view.widthAnchor.constraint(equalToConstant: childContainerView.frame.width).isActive = true
        
        cvc.view.layoutIfNeeded()
        
        if nc == nil {
            nc = PrimerNavigationController(rootViewController: cvc)
            nc!.view.translatesAutoresizingMaskIntoConstraints = false
            
            let availableScreenHeight = UIScreen.main.bounds.size.height - (topPadding + bottomPadding)
            let navigationControllerHeight: CGFloat = (viewController.view.bounds.size.height + nc!.navigationBar.bounds.height) > availableScreenHeight ? availableScreenHeight : (viewController.view.bounds.size.height + nc!.navigationBar.bounds.height)
            let containerViewHeight: CGFloat = navigationControllerHeight
            
            nc!.view.widthAnchor.constraint(equalToConstant: childContainerView.frame.width).isActive = true
            heightConstraint = nc!.view.heightAnchor.constraint(equalToConstant: navigationControllerHeight)
            heightConstraint!.isActive = true
            cvc.view.heightAnchor.constraint(equalToConstant: containerViewHeight).isActive = true
            nc!.view.layoutIfNeeded()
            
            childContainerView.addSubview(nc!.view)
            nc!.view.layoutIfNeeded()
            nc!.didMove(toParent: self)
            
            childContainerViewBottomConstraint.constant = 0.0
            childContainerViewHeightConstraint.constant = nc!.view.frame.height

            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
                self.view.layoutIfNeeded()
            } completion: { _ in

            }
        } else {
            let availableScreenHeight = UIScreen.main.bounds.size.height - (topPadding + bottomPadding)
            let navigationControllerHeight: CGFloat = (viewController.view.bounds.size.height + nc!.navigationBar.bounds.height) > availableScreenHeight ? availableScreenHeight : (viewController.view.bounds.size.height + nc!.navigationBar.bounds.height)
            let containerViewHeight: CGFloat = navigationControllerHeight
            
//            nc!.view.widthAnchor.constraint(equalToConstant: childContainerView.frame.width).isActive = true
            heightConstraint?.isActive = false
            heightConstraint = nc!.view.heightAnchor.constraint(equalToConstant: navigationControllerHeight)
            heightConstraint!.isActive = true
            cvc.view.heightAnchor.constraint(equalToConstant: containerViewHeight).isActive = true
            nc!.pushViewController(cvc, animated: true)
            
            childContainerViewBottomConstraint.constant = 0.0
            childContainerViewHeightConstraint.constant = navigationControllerHeight
            
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
                self.view.layoutIfNeeded()
            } completion: { _ in

            }
        }
    }
    
    func popViewController() {
        guard let nc = nc, nc.viewControllers.count > 1 else {
            return
        }
        
        let viewController = nc.viewControllers[nc.viewControllers.count-2]
        
        let availableScreenHeight = UIScreen.main.bounds.size.height - (topPadding + bottomPadding)
        let navigationControllerHeight: CGFloat = (viewController.view.bounds.size.height + nc.navigationBar.bounds.height) > availableScreenHeight ? availableScreenHeight : (viewController.view.bounds.size.height + nc.navigationBar.bounds.height)
        
//        nc.view.widthAnchor.constraint(equalToConstant: childContainerView.frame.width).isActive = true
        heightConstraint?.isActive = false
        heightConstraint = nc.view.heightAnchor.constraint(equalToConstant: navigationControllerHeight)
        heightConstraint!.isActive = true
        
        childContainerViewBottomConstraint.constant = 0.0
        childContainerViewHeightConstraint.constant = navigationControllerHeight
        
        // FIXME: Scrollview is 44pt less than it should
        
        nc.popViewController(animated: true)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
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
