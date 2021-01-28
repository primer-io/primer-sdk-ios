//
//  RootViewController+Router.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 14/01/2021.
//

import UIKit

protocol RouterDelegate: class {
    func show(_ route: Route)
    func pop()
    func popAllAndShow(_ route: Route)
    func popAndShow(_ route: Route)
}

extension RootViewController: RouterDelegate {
    func show(_ route: Route) {
        
        let vc = route.viewControllerFactory(context, router: self)
        self.add(vc, height: route.height)
        
    }
    
    func pop() {
        popView()
    }
    
    func popAllAndShow(_ route: Route) {
        let vc = route.viewControllerFactory(context, router: self)
        popAllAndShow(vc, height: route.height)
    }
    
    func popAndShow(_ route: Route) {
        let vc = route.viewControllerFactory(context, router: self)
        popAndShow(vc, height: route.height)
    }
}

fileprivate extension RootViewController {
    func add(_ child: UIViewController, height: CGFloat = UIScreen.main.bounds.height * 0.5) {
        
        UIView.animate(withDuration: 0.25, animations: {[weak self] in
            guard let strongSelf = self else { return }
            
            if (strongSelf.context.settings.isFullScreenOnly) {
                strongSelf.heightConstraint.setFullScreen()
                strongSelf.view.layoutIfNeeded()
            } else {
                strongSelf.heightConstraint?.constant = height
                strongSelf.view.layoutIfNeeded()
            }
        })
        //hide previous view
        routes.last?.view.isHidden = true
        routes.append(child)
        heights.append(height)
        currentHeight = height
        addChild(child)
        //view
        mainView.addSubview(child.view)
        child.view.pin(to: mainView)
        //final step
        child.didMove(toParent: self)
    }
    
    func popAllAndShow(_ child: UIViewController, height: CGFloat = UIScreen.main.bounds.height * 0.5) {
        routes.forEach({ controller in
            controller.view.removeFromSuperview()
            controller.removeFromParent()
        })
        routes = []
        add(child, height: height)
    }
    
    func popAndShow(_ child: UIViewController, height: CGFloat = UIScreen.main.bounds.height * 0.5) {
        routes.last?.view.removeFromSuperview()
        routes.last?.removeFromParent()
        routes.removeLast()
        add(child, height: height)
    }
    
    func popView() {
        // dismiss checkout if this is the first route
        if (routes.count < 2) { return dismiss(animated: true) }
        
        // remove view and view controller of foremost route
        routes.last?.view.removeFromSuperview()
        routes.last?.removeFromParent()
        
        print("routes:", routes)
        // remove foremost route from route stack & its associated height
        if (!heights.isEmpty && !routes.isEmpty) {
            routes.removeLast()
            heights.removeLast()
        }
        
        // reveal previous route view & animate height transition
        self.routes.last?.view.isHidden = false
        
        if (self.routes.last is ConfirmMandateViewController) {
            (self.routes.last as! ConfirmMandateViewController).reload()
        }
        
        // animate to previous height
        UIView.animate(withDuration: 0.25, animations: {[weak self] in
            guard let strongSelf = self else { return }
            if (strongSelf.context.settings.isFullScreenOnly) {
                strongSelf.heightConstraint.setFullScreen()
                strongSelf.view.layoutIfNeeded()
            } else {
                strongSelf.heightConstraint?.constant = self?.heights.last ?? 400
                strongSelf.view.layoutIfNeeded()
            }
        })
        
    }
}
