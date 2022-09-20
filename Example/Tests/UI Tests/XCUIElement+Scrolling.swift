//
//  XCUIElement+Scrolling.swift
//  PrimerSDKExample_UITests
//
//  Created by Dario Carlomagno on 05/07/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation
import XCTest

extension XCUIElement {
    
    func scrollRevealingElement(_ element: XCUIElement) -> Bool {
        
        guard self.elementType == .scrollView else {
            return false
        }
        
        let scrollFrame = frame
        var elementFrame = element.frame
        
        // Figure out if we need to scroll up or down
        let direction = elementFrame.origin.y < scrollFrame.origin.y ? 1 : -1
        
        while !scrollFrame.contains(elementFrame) {
            
            let scrollingOffSet = CGFloat(direction * 30) // 30 is an arbitrary offset
            
            if #available(iOS 15.0, *) {
                scroll(byDeltaX: 0, deltaY: scrollingOffSet)
            } else {
                let startCoord = coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
                let endCoord = startCoord.withOffset(CGVector(dx: 0.0, dy: scrollingOffSet));
                startCoord.press(forDuration: 0.01, thenDragTo: endCoord)
            }
            
            let newElementFrame = element.frame
            
            if elementFrame.equalTo(newElementFrame) {
                // scrolling did not move the element
                // either the element is not on this scroll view or
                // we've scrolled the entire scrollview
                break
            }
            
            elementFrame = newElementFrame
        }
        
        return scrollFrame.contains(elementFrame)
    }
}
