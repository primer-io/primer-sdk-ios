import UIKit.UIImage

extension UIImage {
    convenience init?(primerResource: String) {
        self.init(named: primerResource, in: .primerResources, compatibleWith: nil)
    }
}
