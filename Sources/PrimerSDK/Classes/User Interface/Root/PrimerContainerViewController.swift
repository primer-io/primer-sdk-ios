//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

#if canImport(UIKit)

import UIKit

/// PrimerContainerViewController gets a view controller as input. The input view controller must use autolayout.
/// It then sets this view controller as its child, wraps it within a scrollview and sets the constraints needed.
class PrimerContainerViewController: PrimerViewController {
    
    internal var scrollView = UIScrollView()
    internal var childView = PrimerView()
    internal var childViewController: UIViewController
    internal var mockedNavigationBar = PrimerNavigationBar()
    
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
        scrollView.accessibilityIdentifier = "primer_container_scroll_view"

        view.addSubview(mockedNavigationBar)
        mockedNavigationBar.translatesAutoresizingMaskIntoConstraints = false
        mockedNavigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        mockedNavigationBar.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        mockedNavigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        mockedNavigationBar.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        addChild(childViewController)
        scrollView.bounces = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(childView)
        childView.addSubview(childViewController.view)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        childView.translatesAutoresizingMaskIntoConstraints = false
        childViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.topAnchor.constraint(equalTo: mockedNavigationBar.bottomAnchor, constant: 0.0).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0.0).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0.0).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0.0).isActive = true
        
        childView.pin(view: scrollView)
        childViewController.view.pin(view: childView)
        childView.widthAnchor.constraint(equalTo: childViewController.view.widthAnchor).isActive = true
        childViewHeightConstraint = childView.heightAnchor.constraint(equalToConstant: childViewController.view.bounds.size.height)
        childViewHeightConstraint.isActive = true
        view.layoutIfNeeded()

        childViewController.didMove(toParent: self)
        
        scrollView.delegate = self
    }
    
    func layoutContainerViewControllerIfNeeded(block: (() -> Void)?) {
        // This is very important, we need to disable any height constraints before layout.
        self.childViewHeightConstraint?.isActive = false
        self.childViewHeightConstraint = nil
        
        // Run the code block
        block?()
        
        // This is very important, the view must layout in order to have correct height before reseting the constraints.
        self.view.layoutIfNeeded()
        self.childViewHeightConstraint?.isActive = false
        self.childViewHeightConstraint = nil
        childViewHeightConstraint = childView.heightAnchor.constraint(equalToConstant: childViewController.view.bounds.size.height)
        childViewHeightConstraint?.isActive = true
        Primer.shared.primerRootVC?.resetConstraint(for: childViewController)
        view.layoutIfNeeded()
    }
}

extension PrimerContainerViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y == 0 && scrollView.panGestureRecognizer.translation(in: scrollView.superview).y > 0 {
            Primer.shared.dismiss()
        }
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

#endif
