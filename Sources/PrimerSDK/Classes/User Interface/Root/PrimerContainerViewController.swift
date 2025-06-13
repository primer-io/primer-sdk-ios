//
//  PrimerContainerViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 30/7/21.
//

import UIKit

/// PrimerContainerViewController gets a view controller as input. The input view controller must use autolayout.
/// It then sets this view controller as its child, wraps it within a scrollview and sets the constraints needed.
final class PrimerContainerViewController: PrimerViewController {

    internal var scrollView = UIScrollView()
    internal var childView = PrimerView()
    internal var childViewController: UIViewController
    internal var mockedNavigationBar = PrimerNavigationBar()

    init(childViewController: UIViewController) {
        self.childViewController = childViewController
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    var scrollViewHeightConstraint: NSLayoutConstraint!
    var childViewHeightConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.accessibilityIdentifier = "checkout_sheet_content"
        scrollView.accessibilityIdentifier = "primer_container_scroll_view"

        view.addSubview(mockedNavigationBar)
        mockedNavigationBar.translatesAutoresizingMaskIntoConstraints = false
        mockedNavigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        mockedNavigationBar.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        mockedNavigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        mockedNavigationBar.heightAnchor.constraint(equalToConstant: 44).isActive = true
        mockedNavigationBar.addDismissButton()

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
        
        // Use preferredContentSize if available, otherwise fall back to bounds height
        let initialHeight: CGFloat
        if childViewController.preferredContentSize.height > 0 {
            initialHeight = childViewController.preferredContentSize.height
        } else {
            initialHeight = childViewController.view.bounds.size.height
        }
        
        childViewHeightConstraint = childView.heightAnchor.constraint(equalToConstant: initialHeight)
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
        
        // Use preferredContentSize if available, otherwise fall back to bounds height
        let childHeight: CGFloat
        if childViewController.preferredContentSize.height > 0 {
            // Use the preferred content size for dynamic sizing (e.g., SwiftUI bridge controllers)
            childHeight = childViewController.preferredContentSize.height
        } else {
            // Fall back to bounds height for traditional view controllers
            childHeight = childViewController.view.bounds.size.height
        }
        
        // Create new height constraint based on the measured/preferred height
        childViewHeightConstraint = childView.heightAnchor.constraint(equalToConstant: childHeight)
        childViewHeightConstraint?.isActive = true
        
        // Reset the root view controller's constraint to match
        PrimerUIManager.primerRootViewController?.resetConstraint(for: childViewController)
        view.layoutIfNeeded()
    }
}

extension PrimerContainerViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y == 0 && scrollView.panGestureRecognizer.translation(in: scrollView.superview).y > 0 {
            PrimerInternal.shared.dismiss()
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
