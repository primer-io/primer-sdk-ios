//
//  PrimerNavigationController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 30/7/21.
//

import UIKit

/// UINavigationController subclass that intercepts pop, and handles it through the PrimerRootViewController
class PrimerNavigationController: UINavigationController, UINavigationBarDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        
        navigationBar.barStyle = .black
        navigationBar.barTintColor = .white
        navigationBar.isTranslucent = false

        navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 17.0, weight: .semibold)
        ]
    }
    
    func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool {
        Primer.shared.primerRootVC?.popViewController()
        return false
    }
    
}

extension PrimerNavigationController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DissolveAnimator()
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
