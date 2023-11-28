//
//  UITableViewCellExtensions.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 23/01/2021.
//

import UIKit

internal class PrimerTableViewCell: UITableViewCell {

    func addTitle(_ text: String, theme: PrimerThemeProtocol) {
        let titleView = UILabel()
        titleView.text = text
        titleView.textColor = theme.text.subtitle.color
        titleView.font = .systemFont(ofSize: 13, weight: .light)
        titleView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(titleView)
        titleView.topAnchor.constraint(equalTo: self.topAnchor, constant: 8).isActive = true
        titleView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16).isActive = true
    }

    func addContent(_ text: String?, theme: PrimerThemeProtocol) {
        let contentView = UILabel()
        contentView.text = text
        contentView.textColor = theme.text.body.color
        contentView.font = .systemFont(ofSize: 17)
        contentView.adjustsFontSizeToFitWidth = true
        contentView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(contentView)
        contentView.topAnchor.constraint(equalTo: self.topAnchor, constant: 28).isActive = true
        contentView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16).isActive = true
        contentView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -32).isActive = true
    }

}
