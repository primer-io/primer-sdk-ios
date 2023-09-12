//
//  UINavigationController+Extensions.swift
//  PrimerSDK
//
//  Created by Evangelos on 29/4/22.
//



import UIKit

extension UINavigationController {
    func pushViewController(viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        pushViewController(viewController, animated: animated)

        if animated, let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { _ in
                completion?()
            }
        } else {
            completion?()
        }
    }

    func popViewController(animated: Bool, completion: (() -> Void)?) {
        popViewController(animated: animated)

        if animated, let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { _ in
                completion?()
            }
        } else {
            completion?()
        }
    }
    
    func popToViewController(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        popToViewController(viewController, animated: animated)

        if animated, let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { _ in
                completion?()
            }
        } else {
            completion?()
        }
    }
}


