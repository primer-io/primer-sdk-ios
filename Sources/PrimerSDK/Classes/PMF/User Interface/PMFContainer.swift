//
//  PMFContainer.swift
//  PrimerSDK
//
//  Created by Evangelos on 9/11/22.
//

#if canImport(UIKit)

import UIKit

extension PMF.UserInterface {
    
    class Container: UIStackView {
        
        let component: PMF.Component.Container
        let params: [String: String?]?
        
        required init(containerComponent: PMF.Component.Container, params: [String: String?]?) {
            self.component = containerComponent
            self.params = params
            super.init(frame: .zero)
            
            self.axis = component.orientation == .horizontal ? .horizontal : .vertical
            self.distribution = .fill
            
            for subComponent in component.components {
                guard let view = PMF.UserInterface.createView(for: subComponent, with: self.params) else { continue }
                self.addArrangedSubview(view)
            }
        }
        
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

#endif
