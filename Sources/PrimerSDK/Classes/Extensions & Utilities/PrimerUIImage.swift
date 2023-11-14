//
//  PrimerUIImage.swift
//  PrimerSDK
//
//  Copyright © 2022 Primer API ltd. All rights reserved.
//

import UIKit

internal class PrimerUIImage: UIImage {}

extension PrimerUIImage {

    func withColor(_ color: UIColor) -> UIImage? {

        if #available(iOS 13.0, *) {
            return self.withTintColor(color)
        } else {
            UIGraphicsBeginImageContextWithOptions(size, false, scale)
            let drawRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            color.setFill()
            UIRectFill(drawRect)
            draw(in: drawRect, blendMode: .destinationIn, alpha: 1)
            let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return tintedImage!
        }
    }
}
