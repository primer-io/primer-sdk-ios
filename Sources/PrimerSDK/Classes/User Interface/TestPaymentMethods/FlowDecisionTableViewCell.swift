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
        layer.cornerRadius = 8
        layer.borderWidth = 1
        clipsToBounds = true
        textLabel?.font = .systemFont(ofSize: 16)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var frame: CGRect {
        get {
            return super.frame
        }
        set (newFrame) {
            var frame =  newFrame
            frame.origin.y += 4
            frame.size.height -= 2 * 4
            super.frame = frame
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            layer.borderColor = UIColor.systemBlue.cgColor
            accessoryType = .checkmark
        } else {
            layer.borderColor = UIColor.systemGray.cgColor
            accessoryType = .none
        }
    }
}

extension FlowDecisionTableViewCell {
    
    func configure(decision: PrimerTestPaymentMethodOptions.FlowDecision) {
        self.decision = decision
        textLabel?.text = decision.displayFlowTitle
    }
}

#endif
