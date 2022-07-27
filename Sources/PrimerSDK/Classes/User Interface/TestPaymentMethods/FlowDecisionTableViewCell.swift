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

class FlowDecisionTableViewCell: UITableViewCell {
    
    static var identifier: String = "FlowDecisionTableViewCell"
        
    internal private(set) var decision: PrimerTestPaymentMethodOptions.FlowDecision!
    private let cellInternalPadding: CGFloat = 4
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
            frame.origin.y += cellInternalPadding
            frame.size.height -= 2 * cellInternalPadding
            super.frame = frame
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            layer.borderColor = PrimerColor.blue.cgColor
            accessoryType = .checkmark
        } else {
            layer.borderColor = UIColor(red: 229/255, green: 229/255, blue: 234/255, alpha: 1).cgColor
            accessoryType = .none
        }
    }
}

extension FlowDecisionTableViewCell {
    
    func configure(decision: PrimerTestPaymentMethodOptions.FlowDecision) {
        self.decision = decision
        textLabel?.text = decision.displayFlowTitle
        accessibilityIdentifier = "decision_\(decision)"
    }
}

#endif
