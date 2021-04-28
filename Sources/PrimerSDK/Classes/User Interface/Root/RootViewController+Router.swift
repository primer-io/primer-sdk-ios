//
//  RootViewController+Router.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 14/01/2021.
//

#if canImport(UIKit)

import UIKit

protocol RouterDelegate: class {
    func setRoot(_ root: RootViewController)
    func show(_ route: Route)
    func pop()
    func popAllAndShow(_ route: Route)
    func popAndShow(_ route: Route)
}

class Router: RouterDelegate {

    weak var root: RootViewController?
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func setRoot(_ root: RootViewController) {
        self.root = root
    }

    func show(_ route: Route) {
        guard let root = self.root else { return }
        guard let vc = route.viewController else { return }
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

        if vc is SuccessViewController {
            if settings.hasDisabledSuccessScreen {
                return root.dismiss(animated: true, completion: nil)
            }

            root.view.endEditing(true)

        } else if vc is ErrorViewController {
            if settings.hasDisabledSuccessScreen {
                return root.dismiss(animated: true, completion: nil)
            }
            
            root.view.endEditing(true)
        }

        root.add(vc, height: route.height)
    }

    func pop() {
        root?.popView()
    }

    func popAllAndShow(_ route: Route) {
        guard let vc = route.viewController else { return }
        root?.popAllAndShow(vc, height: route.height)
    }

    func popAndShow(_ route: Route) {
        guard let vc = route.viewController else { return }
        root?.popAndShow(vc, height: route.height)
    }
}

fileprivate extension RootViewController {
    func add(_ child: UIViewController, height: CGFloat = UIScreen.main.bounds.height * 0.5) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        UIView.animate(withDuration: 0.25, animations: {[weak self] in
            guard let strongSelf = self else { return }

            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            if settings.isFullScreenOnly {
//                strongSelf.view.layoutIfNeeded()
            } else {
                strongSelf.heightConstraint?.constant = height
                strongSelf.view.layoutIfNeeded()
            }
        })

        // hide previous view
        routes.last?.view.isHidden = true
        routes.append(child)
        heights.append(height)
        currentHeight = height
        addChild(child)
        // view
        mainView.addSubview(child.view)

        child.view.pin(to: mainView)
        child.didMove(toParent: self)

        if self.routes.last is ConfirmMandateViewController {
            state.directDebitFormCompleted = true
        }
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
        if routes.count < 2 { return dismiss(animated: true) }

        // remove view and view controller of foremost route
        routes.last?.view.removeFromSuperview()
        routes.last?.removeFromParent()

        log(logLevel: .debug, title: nil, message: "Routes: \(routes)", prefix: nil, suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)
        // remove foremost route from route stack & its associated height
        if !heights.isEmpty && !routes.isEmpty {
            routes.removeLast()
            heights.removeLast()
            currentHeight = heights[heights.count - 1]
        }

        // reveal previous route view & animate height transition
        self.routes.last?.view.isHidden = false

        if self.routes.last is ConfirmMandateViewController {
            (self.routes.last as! ConfirmMandateViewController).reload()
        }

        // animate to previous height
        UIView.animate(withDuration: 0.25, animations: {[weak self] in
            guard let strongSelf = self else { return }
            
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            if settings.isFullScreenOnly {
                strongSelf.heightConstraint.setFullScreen()
                strongSelf.view.layoutIfNeeded()
            } else {
                strongSelf.heightConstraint?.constant = self?.heights.last ?? 400
                strongSelf.view.layoutIfNeeded()
            }
        })

    }
}

#endif
