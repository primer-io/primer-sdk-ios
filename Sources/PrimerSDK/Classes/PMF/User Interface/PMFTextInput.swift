//
//  PMFTextInput.swift
//  PrimerSDK
//
//  Created by Evangelos on 3/11/22.
//

#if canImport(UIKit)

import UIKit

extension PMF.UserInterface {
    
    class TextInput: UITextField {
        
        var component: PMF.Component.TextInput
        
        required init(textInputComponent: PMF.Component.TextInput) {
            self.component = textInputComponent
            super.init(frame: .zero)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

#endif
