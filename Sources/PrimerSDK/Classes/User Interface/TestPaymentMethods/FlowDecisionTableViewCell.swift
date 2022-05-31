//
//  FlowDecisionTableViewCell.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 29/05/22.
//

#if canImport(UIKit)

import UIKit

class FlowDecisionTableViewCell: UITableViewCell {
    
    static var identifier: String = "FlowDecisionTableViewCell"
        
    internal private(set) var decision: PrimerTestPaymentMethodOptions.FlowDecision!
        
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.preservesSuperviewLayoutMargins = false
        self.contentView.preservesSuperviewLayoutMargins = false
        self.selectionStyle = .none
        
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        backgroundColor = theme.view.backgroundColor
        layer.cornerRadius = theme.view.cornerRadius
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(decision: PrimerTestPaymentMethodOptions.FlowDecision) {
        self.decision = decision
        textLabel?.text = decision.displayFlowTitle
    }
}

#endif
