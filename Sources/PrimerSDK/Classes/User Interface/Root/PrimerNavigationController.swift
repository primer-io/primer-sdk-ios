//
//  PrimerNavigationController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 30/7/21.
//

import UIKit

/// UINavigationController subclass that intercepts pop, and handles it through the PrimerRootViewController
class PrimerNavigationController: UINavigationController, UINavigationBarDelegate {

    var isInitialized = false

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
        setNavigationBarHidden(true, animated: false)
    }

    func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool {
        PrimerUIManager.primerRootViewController?.popViewController()
        return false
    }

}

extension PrimerNavigationController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DissolveAnimator()
    }

    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController,
                              animated: Bool) {
        if isInitialized {
            navigationBar.layer.removeAllAnimations()
            let navigationBarAnimation = CATransition()
            navigationBarAnimation.duration = 0.3
            navigationBarAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
            navigationBarAnimation.type = CATransitionType.fade
            navigationBarAnimation.subtype = .none
            navigationBarAnimation.isRemovedOnCompletion = true
            navigationBar.layer.add(navigationBarAnimation, forKey: nil)
        } else {
            isInitialized = true
        }
    }

    func navigationController(_ navigationController: UINavigationController,
                              didShow viewController: UIViewController,
                              animated: Bool) {
        if viewController == self {
            if isInitialized {
                navigationBar.layer.removeAllAnimations()
            }
        }
    }
}

internal final class DissolveAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    let animationDuration = 0.25

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return animationDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)
        toVC?.view.alpha = 0.0
        let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)
        transitionContext.containerView.addSubview(fromVC!.view)
        transitionContext.containerView.addSubview(toVC!.view)

        UIView.animate(withDuration: 0.290, delay: 0.160, options: .curveEaseInOut) {
            toVC?.view.alpha = 1.0
        } completion: { _ in
            fromVC?.view.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }

}
