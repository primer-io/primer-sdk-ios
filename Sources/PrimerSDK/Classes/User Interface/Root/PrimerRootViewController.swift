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
    
    private var nc: UINavigationController?
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
        let lvc = PrimerLoadingViewController()
//        lvc.view.translatesAutoresizingMaskIntoConstraints = false
        lvc.view.widthAnchor.constraint(equalToConstant: self.childContainerView.frame.width).isActive = true
        lvc.view.heightAnchor.constraint(equalToConstant: 300).isActive = true
//        lvc.view.layoutIfNeeded()
        self.show(viewController: lvc)
        
        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
            let lvc2 = PrimerLoadingViewController()
    //        lvc.view.translatesAutoresizingMaskIntoConstraints = false
            lvc2.view.widthAnchor.constraint(equalToConstant: self.childContainerView.frame.width).isActive = true
            lvc2.view.heightAnchor.constraint(equalToConstant: 3000).isActive = true
    //        lvc.view.layoutIfNeeded()
            self.show(viewController: lvc2)
        }
    }
    
    var heightConstraint: NSLayoutConstraint?
    
    func show(viewController: UIViewController) {
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.layoutIfNeeded()
        
        let cvc = PrimerContainerViewController(childViewController: viewController)
        cvc.view.translatesAutoresizingMaskIntoConstraints = false
        cvc.view.widthAnchor.constraint(equalToConstant: childContainerView.frame.width).isActive = true
        
        cvc.view.layoutIfNeeded()
        
        if nc == nil {
            nc = UINavigationController(rootViewController: cvc)
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
            
            nc!.view.widthAnchor.constraint(equalToConstant: childContainerView.frame.width).isActive = true
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
    
    var scrollViewHeightConstraint: NSLayoutConstraint!
    var childViewHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.bounces = false
                
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
        
//        let availableScreenHeight = UIScreen.main.bounds.size.height - (topPadding + bottomPadding)
//        let scrollViewHeight: CGFloat = childViewController.view.bounds.size.height > availableScreenHeight ? availableScreenHeight : childViewController.view.bounds.size.height
        
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
//        scrollViewHeightConstraint = scrollView.heightAnchor.constraint(equalToConstant: scrollViewHeight)
//        scrollViewHeightConstraint.isActive = true
        
        scrollView.addSubview(childView)
        childView.translatesAutoresizingMaskIntoConstraints = false
        childView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 0).isActive = true
        childView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 0).isActive = true
        childView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 0).isActive = true
        childView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: 0).isActive = true
        childView.widthAnchor.constraint(equalToConstant: view.frame.size.width).isActive = true
        childViewHeightConstraint = childView.heightAnchor.constraint(equalToConstant: childViewController.view.bounds.size.height)
        childViewHeightConstraint.isActive = true

        childView.addSubview(childViewController.view)
        childViewController.didMove(toParent: self)
    }
}

class PrimerLoadingViewController: PrimerViewController {
    
    private var activityIndicatorView: UIActivityIndicatorView = UIActivityIndicatorView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        view.addSubview(activityIndicatorView)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        activityIndicatorView.widthAnchor.constraint(equalToConstant: 50.0).isActive = true
        activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        activityIndicatorView.startAnimating()
    }
    
}
