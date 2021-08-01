//
//  PrimerContainerViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 30/7/21.
//

import UIKit

/// PrimerContainerViewController gets a view controller as input. The input view controller must use autolayout.
/// It then sets this view controller as its child, wraps it within a scrollview and sets the constraints needed.
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

extension UIView {
    
    func pin(view: UIView, leading: CGFloat = 0, top: CGFloat = 0, trailing: CGFloat = 0, bottom: CGFloat = 0) {
        topAnchor.constraint(equalTo: view.topAnchor, constant: top).isActive = true
        bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: bottom).isActive = true
        leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: leading).isActive = true
        trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: trailing).isActive = true
    }
    
}
