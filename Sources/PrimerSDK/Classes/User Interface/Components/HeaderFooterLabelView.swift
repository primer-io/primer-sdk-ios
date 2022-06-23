#if canImport(UIKit)

import Foundation
import UIKit

class HeaderFooterLabelView: UITableViewHeaderFooterView {

    private let label = UILabel(frame: .zero)
    private let labelNumberOfLines = 0
    private let systemFontSize: CGFloat = 16
    private let padding: CGFloat = 16

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        let containerView = UIView(frame: .zero)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear

        contentView.addSubview(containerView)
        containerView.addSubview(label)

        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = labelNumberOfLines
        label.font = .systemFont(ofSize: systemFontSize)
        
        label.pin(view: containerView, leading: 0, top: 0, trailing: 0, bottom: -padding)
        containerView.pin(view: contentView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension HeaderFooterLabelView {
    
    func configure(text: String) {
        label.text = text
    }
}

#endif
