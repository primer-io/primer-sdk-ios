//
//  UIScrollViewExtension.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 18/3/21.
//

import UIKit

internal class PrimerScrollView: UIScrollView {

    func scrollToBottom(animated: Bool) {
        let bottomOffset = CGPoint(x: 0, y: contentSize.height - bounds.height + contentInset.bottom)
        setContentOffset(bottomOffset, animated: animated)
    }

    func scrollToTop(animated: Bool) {
        let desiredOffset = CGPoint(x: 0, y: -contentInset.top)
        setContentOffset(desiredOffset, animated: animated)
    }

}
