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

class PrimerStateField: PrimerCardFormFieldProtocol {
    
    private static let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    static func stateFieldContainerViewFieldView(_ primerTextFieldView: PrimerTextFieldView) -> PrimerCustomFieldView {
        let stateFieldContainerView = PrimerCustomFieldView()
        stateFieldContainerView.fieldView = primerTextFieldView
        stateFieldContainerView.placeholderText = Strings.CardFormView.State.label
        stateFieldContainerView.setup()
        stateFieldContainerView.tintColor = theme.input.border.color(for: .selected)
        return stateFieldContainerView
    }
    
    static func stateFieldViewWithDelegate(_ delegate: PrimerTextFieldViewDelegate?) -> PrimerStateFieldView {
        let stateFieldView = PrimerStateFieldView()
        stateFieldView.placeholder = Strings.CardFormView.State.placeholder
        stateFieldView.heightAnchor.constraint(equalToConstant: 36).isActive = true
        stateFieldView.textColor = theme.input.text.color
        stateFieldView.delegate = delegate
        return stateFieldView
    }
}

#endif
