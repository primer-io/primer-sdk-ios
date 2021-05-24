#if canImport(UIKit)

import UIKit

public class PresentationController: UIPresentationController {

    let blurEffectView: UIVisualEffectView!
    var tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer()

    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        let blurEffect = UIBlurEffect(style: .dark)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissController))
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.blurEffectView.isUserInteractionEnabled = true
        self.blurEffectView.addGestureRecognizer(tapGestureRecognizer)
    }

    //    public override var frameOfPresentedViewInContainerView: CGRect {
    //        return CGRect(
    //            origin: CGPoint(x: 0, y: self.containerView!.frame.height * 0.5),
    //            size: CGSize(width: self.containerView!.frame.width,height: self.containerView!.frame.height * 0.5)
    //        )
    //    }

    public override func presentationTransitionWillBegin() {
        self.blurEffectView.alpha = 0
        self.containerView?.addSubview(blurEffectView)
        self.presentedViewController.transitionCoordinator?.animate(alongsideTransition: { (_) in
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            
            switch Primer.shared.flow.internalSessionFlow {
            case .vaultKlarna,
                 .vaultPayPal,
                 .checkoutWithKlarna:
                self.blurEffectView.alpha = settings.isInitialLoadingHidden ? 0 : 0.7
            default:
                self.blurEffectView.alpha = 0.7
            }
            
        }, completion: { (_) in })
    }

    public override func dismissalTransitionWillBegin() {
        self.presentedViewController.transitionCoordinator?.animate(alongsideTransition: { (_) in
            self.blurEffectView.alpha = 0
        }, completion: { (_) in
            self.blurEffectView.removeFromSuperview()
        })
    }

    public override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        presentedView!.roundCorners([.topLeft, .topRight], radius: 22)
    }

    public override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        presentedView?.frame = frameOfPresentedViewInContainerView
        blurEffectView.frame = containerView!.bounds
    }

    @objc func dismissController() {
        self.presentedViewController.dismiss(animated: true, completion: nil)
    }
}

internal extension UIView {
    
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
    
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }
    
}

#endif
