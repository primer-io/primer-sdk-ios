// ////
// ////  RootViewController+Router.swift
// ////  PrimerSDK
// ////
// ////  Created by Carl Eriksson on 14/01/2021.
// ////
// //
// //  RootViewController+Router.swift
// //  PrimerSDK
// //
// //  Created by Carl Eriksson on 14/01/2021.
// //

// #if canImport(UIKit)

// import UIKit

// protocol RouterDelegate: AnyObject {
//     var root: RootViewController? { get }
//     func setRoot(_ root: RootViewController)
//     func show(_ route: Route)
//     func pop()
//     func popAllAndShow(_ route: Route)
//     func popAndShow(_ route: Route)
//     func presentSuccessScreen(for successScreenType: SuccessScreenType)
//     func presentErrorScreen(with err: Error)
// }

// internal class Router: RouterDelegate {

//     weak var root: RootViewController?
//     var currentRoute: Route?
    
//     deinit {
//         log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
//     }

//     func setRoot(_ root: RootViewController) {
//         self.root = root
//     }

//     func show(_ route: Route) {
//         guard let root = self.root else { return }
//         guard let vc = route.viewController else { return }
//         self.currentRoute = route
//         let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

//         // FIXME: No decisions on UI elements
//         if vc is SuccessViewController {
//             if settings.hasDisabledSuccessScreen {
//                 Primer.shared.dismiss()
//                 return
//             }

//             root.view.endEditing(true)

//         } else if vc is ErrorViewController {
//             if settings.hasDisabledSuccessScreen {
//                 Primer.shared.dismiss()
//                 return
//             }
            
//             root.view.endEditing(true)
//         }

//         switch route {
//         case .form:
//             root.add(vc, height: route.height, animateOnPush: false)
//         default:
//             root.add(vc, height: route.height)
//         }
//     }

//     func pop() {
//         switch currentRoute {
//         case .form:
//             root?.popView(animateOnPop: false)
//         default:
//             root?.popView()
//         }
//     }

//     func popAllAndShow(_ route: Route) {
//         guard let vc = route.viewController else { return }
//         root?.popAllAndShow(vc, height: route.height)
//     }

//     func popAndShow(_ route: Route) {
//         guard let vc = route.viewController else { return }
//         root?.popAndShow(vc, height: route.height)
//     }
    
//     func presentErrorScreen(with err: Error) {
//         let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
//         if !settings.hasDisabledSuccessScreen {
//             Primer.shared.root = RootViewController()
//             setRoot(Primer.shared.root!)
//             show(.error(error: err))
//             Primer.shared.presentingViewController?.present(Primer.shared.root!, animated: true)
//         }
//     }
    
//     func presentSuccessScreen(for successScreenType: SuccessScreenType = .regular) {
//         let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
//         if !settings.hasDisabledSuccessScreen {
//             Primer.shared.root = RootViewController()
//             setRoot(Primer.shared.root!)
//             show(.success(type: successScreenType))
//             Primer.shared.presentingViewController?.present(Primer.shared.root!, animated: true)
//         }
//     }
    
// }

// fileprivate extension RootViewController {
    
//     // FIXME: Can't all this logic be resolved with a UINavigationController?
//     func add(_ child: UIViewController, height: CGFloat = UIScreen.main.bounds.height * 0.5, animateOnPush: Bool = true) {
//         let state: AppStateProtocol = DependencyContainer.resolve()
//         let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
//         if !settings.isFullScreenOnly {
//             heightConstraint?.constant = height
//         }
        
//         if animateOnPush {
//             UIView.animate(withDuration: 0.25, delay: 0, options: UIView.AnimationOptions(rawValue: 7)) {
//                 let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
//                 if settings.isFullScreenOnly {
//                     // ...
//                 } else {
//                     self.heightConstraint?.constant = height
//                     self.view.layoutIfNeeded()
//                 }
//             } completion: { finished in
                
//             }
//         } else {
//             // Do not change the view's height here, it should be changed when keyboard shows.
//         }
        
//         // hide previous view
//         routes.last?.view.isHidden = true
//         routes.append(child)
//         heights.append(height)
//         currentHeight = height
//         addChild(child)
//         // view
//         mainView.addSubview(child.view)

//         child.view.translatesAutoresizingMaskIntoConstraints = false
//         child.view.topAnchor.constraint(equalTo: mainView.topAnchor).isActive = true
//         child.view.leadingAnchor.constraint(equalTo: mainView.leadingAnchor).isActive = true
//         child.view.trailingAnchor.constraint(equalTo: mainView.trailingAnchor).isActive = true
//         child.view.bottomAnchor.constraint(equalTo: mainView.bottomAnchor).isActive = true
        
//         child.didMove(toParent: self)

//         if self.routes.last is ConfirmMandateViewController {
//             state.directDebitFormCompleted = true
//         }
//     }

//     func popAllAndShow(_ child: UIViewController, height: CGFloat = UIScreen.main.bounds.height * 0.5) {
//         routes.forEach({ controller in
//             controller.view.removeFromSuperview()
//             controller.removeFromParent()
//         })
//         routes = []
//         add(child, height: height)
//     }

//     func popAndShow(_ child: UIViewController, height: CGFloat = UIScreen.main.bounds.height * 0.5) {
//         routes.last?.view.removeFromSuperview()
//         routes.last?.removeFromParent()
//         routes.removeLast()
//         add(child, height: height)
//     }

//     func popView(animateOnPop: Bool = true) {
//         // dismiss checkout if this is the first route
//         if routes.count < 2 { return dismiss(animated: true) }

//         // remove view and view controller of foremost route
//         routes.last?.view.removeFromSuperview()
//         routes.last?.removeFromParent()

//         log(logLevel: .debug, title: nil, message: "Routes: \(routes)", prefix: nil, suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)
//         // remove foremost route from route stack & its associated height
//         if !heights.isEmpty && !routes.isEmpty {
//             routes.removeLast()
//             heights.removeLast()
//             currentHeight = heights[heights.count - 1]
//         }

//         // reveal previous route view & animate height transition
//         self.routes.last?.view.isHidden = false

//         if self.routes.last is ConfirmMandateViewController {
//             (self.routes.last as! ConfirmMandateViewController).reload()
//         }
        
//         let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
//         if settings.isFullScreenOnly {
//             heightConstraint.setFullScreen()
//         } else {
//             heightConstraint?.constant = heights.last ?? 400
//         }

//         // animate to previous height
//         if animateOnPop {
//             UIView.animate(withDuration: 0.25, animations: {[weak self] in
//                 guard let strongSelf = self else { return }
                
//                 let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
//                 if settings.isFullScreenOnly {
//                     strongSelf.heightConstraint.setFullScreen()
//                     strongSelf.view.layoutIfNeeded()
//                 } else {
//                     strongSelf.heightConstraint?.constant = self?.heights.last ?? 400
//                     strongSelf.view.layoutIfNeeded()
//                 }
//             })
//         }
//     }
// }

// #endif
