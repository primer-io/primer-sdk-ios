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
}

extension RootViewController: RouterDelegate {
    func show(_ route: Route) {
        let vc = route.viewControllerFactory(context, router: self)
        self.add(vc, height: route.height)
    }
    
    func pop() {
        popView()
    }
}

fileprivate extension RootViewController {
    func add(_ child: UIViewController, height: CGFloat = UIScreen.main.bounds.height * 0.5) {
        UIView.animate(withDuration: 0.25, animations: {[weak self] in
            guard let strongSelf = self else { return }
            strongSelf.myViewHeightConstraint.constant = height
            strongSelf.view.layoutIfNeeded()
        })
        //hide previous view
        routes.last?.view.isHidden = true
        routes.append(child)
        heights.append(height)
        addChild(child)
        //view
        mainView.addSubview(child.view)
        child.view.pin(to: mainView)
        //final step
        child.didMove(toParent: self)
    }
    
    func popView() {
        // remove view and view controller of foremost route
        routes.last?.view.removeFromSuperview()
        routes.last?.removeFromParent()
        
        // dismiss checkout if this is the first route
        if (routes.count == 0) { return dismiss(animated: true) }
        
        // remove foremost route from route stack & its associated height
        routes.removeLast()
        heights.removeLast()
        
        // reveal previous route view & animate height transition
        self.routes.last?.view.isHidden = false
        
        // animate to previous height
        UIView.animate(withDuration: 0.25, animations: {[weak self] in
            self?.myViewHeightConstraint.constant = (self?.heights.last) ?? 400
            self?.view.layoutIfNeeded()
        })
        
    }
}
