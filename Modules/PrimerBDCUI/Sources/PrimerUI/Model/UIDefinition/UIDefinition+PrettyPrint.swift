//
//  UIDefinition+PrettyPrint.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation

extension UIDefinition {
    func prettyTreeDescription() -> String {
        let header = "┌─ [SDUI RENDER]"
        let rule = header.padding(toLength: max(header.count, 48), withPad: "─", startingAt: 0)
        var lines: [String] = [rule]
        appendTree(prefix: "", isRoot: true, isLast: true, into: &lines)
        lines.append(String(repeating: "─", count: rule.count))
        return lines.joined(separator: "\n")
    }

    private func appendTree(prefix: String, isRoot: Bool, isLast: Bool, into lines: inout [String]) {
        let connector = isRoot ? "" : (isLast ? "└─ " : "├─ ")
        lines.append(prefix + connector + label)

        let childPrefix = isRoot ? "" : prefix + (isLast ? "   " : "│  ")
        for (index, child) in treeChildren.enumerated() {
            child.appendTree(
                prefix: childPrefix,
                isRoot: false,
                isLast: index == treeChildren.count - 1,
                into: &lines
            )
        }
    }

    private var treeChildren: [UIDefinition] {
        switch component {
        case let .button(content, _): content.children
        case let .list(content, _): content.children
        case let .navigation(screens, _): screens
        default: children ?? []
        }
    }

    private var label: String {
        var parts = [component.typeName]
        if let componentID { parts.append(": #\(componentID)") }
        switch component {
        case let .text(props): parts.append(": “\(props.text)”")
        case let .selectionOption(props): parts.append(": \(props.value)")
        default: break
        }
        if case let .string(expr) = visible { parts.append("visible?(\(expr))") }
        return parts.joined(separator: " ")
    }
}

private extension Component {
    var typeName: String {
        switch self {
        case .box: "Box"
        case .button: "Button"
        case .checkbox: "Checkbox"
        case .column: "Column"
        case .container: "Container"
        case .image: "Image"
        case .navigation: "NavigationContainer"
        case .progressIndicator: "ProgressIndicator"
        case .radioButton: "RadioButton"
        case .row: "Row"
        case .selectionOption: "SelectionOption"
        case .list: "List"
        case .selectionGroup: "SelectionGroup"
        case .text: "Text"
        case .textField: "TextField"
        case .spacer: "Spacer"
        case let .custom(type, _): type
        }
    }
}
