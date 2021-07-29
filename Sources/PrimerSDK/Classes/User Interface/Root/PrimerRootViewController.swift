//
//  PrimerRootViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 27/7/21.
//

import UIKit

class PrimerRootViewController: UIViewController {

    @IBOutlet weak var childContainerView: UIView!
    @IBOutlet weak var childContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var childContainerViewBottomConstraint: NSLayoutConstraint!
        
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        show()
    }
    
    func show() {
        let fvc = PrimerCardFormViewController(flow: .checkout)
        fvc.view.translatesAutoresizingMaskIntoConstraints = false
        fvc.view.widthAnchor.constraint(equalToConstant: childContainerView.frame.width).isActive = true
        childContainerViewBottomConstraint.constant = -fvc.view.bounds.height
        fvc.view.layoutIfNeeded()
        
        let cvc = PrimerContainerViewController(childViewController: fvc)
        cvc.view.translatesAutoresizingMaskIntoConstraints = false
        cvc.view.widthAnchor.constraint(equalToConstant: childContainerView.frame.width).isActive = true
        cvc.view.layoutIfNeeded()
        
        let nc = UINavigationController(rootViewController: cvc)
        nc.view.translatesAutoresizingMaskIntoConstraints = false
        
        var topPadding: CGFloat = 0.0
        var bottomPadding: CGFloat = 0.0
        
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
        
        let availableScreenHeight = UIScreen.main.bounds.size.height - (topPadding + bottomPadding)
        let navigationControllerHeight: CGFloat = (cvc.view.bounds.size.height + nc.navigationBar.bounds.height) > availableScreenHeight ? availableScreenHeight : (cvc.view.bounds.size.height + nc.navigationBar.bounds.height)
        nc.view.widthAnchor.constraint(equalToConstant: childContainerView.frame.width).isActive = true
        nc.view.heightAnchor.constraint(equalToConstant: navigationControllerHeight).isActive = true
        nc.view.layoutIfNeeded()
        
        childContainerView.addSubview(nc.view)
        nc.view.layoutIfNeeded()
        nc.didMove(toParent: self)
        
        childContainerViewBottomConstraint.constant = 0.0
        childContainerViewHeightConstraint.constant = nc.view.frame.height

        UIView.animate(withDuration: 0.3, delay: 1, options: .curveEaseInOut) {
            self.view.layoutIfNeeded()
        } completion: { _ in

        }
        
        
        
        
        
        
        
//        let fvc = PrimerCardFormViewController(flow: .checkout)
//        fvc.view.translatesAutoresizingMaskIntoConstraints = false
//        fvc.view.widthAnchor.constraint(equalToConstant: childContainerView.frame.width).isActive = true
//        childContainerViewBottomConstraint.constant = -fvc.view.bounds.height
//        fvc.view.layoutIfNeeded()
//
//        let cvc = PrimerContainerViewController(childViewController: fvc)
//        cvc.view.translatesAutoresizingMaskIntoConstraints = false
//        cvc.view.widthAnchor.constraint(equalToConstant: childContainerView.frame.width).isActive = true
//        cvc.view.layoutIfNeeded()
//
//        childContainerView.addSubview(cvc.view)
//        cvc.view.layoutIfNeeded()
//        cvc.didMove(toParent: self)
//
//        childContainerViewBottomConstraint.constant = 0.0
//        childContainerViewHeightConstraint.constant = cvc.view.frame.height
//
//        UIView.animate(withDuration: 0.3, delay: 1, options: .curveEaseInOut) {
//            self.view.layoutIfNeeded()
//        } completion: { _ in
//
//        }
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

class PrimerContainerViewController: PrimerViewController {
    
    internal var scrollView = UIScrollView()
    internal var childView = UIView()
    internal var childViewController: UIViewController
    
    init(childViewController: UIViewController) {
        self.childViewController = childViewController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        var topPadding: CGFloat = 0.0
        var bottomPadding: CGFloat = 0.0
        
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
        
        let availableScreenHeight = UIScreen.main.bounds.size.height - (topPadding + bottomPadding)
        let scrollViewHeight: CGFloat = childViewController.view.bounds.size.height > availableScreenHeight ? availableScreenHeight : childViewController.view.bounds.size.height
        
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 11.0, *) {
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
        } else {
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        }
        if #available(iOS 11.0, *) {
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
        } else {
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
        }
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        scrollView.heightAnchor.constraint(equalToConstant: scrollViewHeight).isActive = true
        
        scrollView.addSubview(childView)
        childView.translatesAutoresizingMaskIntoConstraints = false
        childView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 0).isActive = true
        childView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 0).isActive = true
        childView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 0).isActive = true
        childView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: 0).isActive = true
        childView.widthAnchor.constraint(equalToConstant: view.frame.size.width).isActive = true
        childView.heightAnchor.constraint(equalToConstant: childViewController.view.bounds.size.height).isActive = true


        childView.addSubview(childViewController.view)
        childViewController.didMove(toParent: self)
    }
}
