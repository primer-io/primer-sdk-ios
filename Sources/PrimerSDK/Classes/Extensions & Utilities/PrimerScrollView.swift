//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

#if canImport(UIKit)

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

#endif
