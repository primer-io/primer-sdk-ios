//
//  RootViewController+Router.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 14/01/2021.
//

#if canImport(UIKit)

import UIKit

protocol RouterDelegate: class {
    var root: RootViewController? { get }
    func setRoot(_ root: RootViewController)
    func show(_ route: Route)
    func pop()
    func popAllAndShow(_ route: Route)
    func popAndShow(_ route: Route)
    func presentSuccessScreen(for successScreenType: SuccessScreenType)
    func presentErrorScreen(with err: Error)
}

internal class Router: RouterDelegate {

    weak var root: RootViewController?
    var currentRoute: Route?
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func setRoot(_ root: RootViewController) {
        self.root = root
    }

    func show(_ route: Route) {
        guard let root = self.root else { return }
        guard let vc = route.viewController else { return }
        self.currentRoute = route
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

        // FIXME: No decisions on UI elements
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

        switch route {
        case .form:
            root.add(vc, height: route.height, animateOnPush: false)
        default:
            root.add(vc, height: route.height)
        }
    }

    func pop() {
        switch currentRoute {
        case .form:
            root?.popView(animateOnPop: false)
        default:
            root?.popView()
        }
    }

    func popAllAndShow(_ route: Route) {
        guard let vc = route.viewController else { return }
        root?.popAllAndShow(vc, height: route.height)
    }

    func popAndShow(_ route: Route) {
        guard let vc = route.viewController else { return }
        root?.popAndShow(vc, height: route.height)
    }
    
    func presentErrorScreen(with err: Error) {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        if !settings.hasDisabledSuccessScreen {
            Primer.shared.root = RootViewController()
            setRoot(Primer.shared.root!)
            show(.error(error: err))
            Primer.shared.presentingViewController?.present(Primer.shared.root!, animated: true)
        }
    }
    
    func presentSuccessScreen(for successScreenType: SuccessScreenType = .regular) {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        if !settings.hasDisabledSuccessScreen {
            Primer.shared.root = RootViewController()
            setRoot(Primer.shared.root!)
            show(.success(type: successScreenType))
            Primer.shared.presentingViewController?.present(Primer.shared.root!, animated: true)
        }
    }
    
}

#endif
