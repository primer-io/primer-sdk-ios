//
//  LayoutView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation

@available(iOS 16.0, *)
struct LayoutView: View {
    let focusedFieldID: FocusState<String?>.Binding
    let uiDefinition: UIDefinition
    let screenID: String

    @EnvironmentObject private var viewModel: SDUIViewModel
    
    var body: some View {
        ComponentView(
            component: uiDefinition.component,
            fieldID: uiDefinition.componentID,
            screenID: screenID,
            focusedFieldID: focusedFieldID,
            visible: uiDefinition.visible,
            slots: uiDefinition.slots,
            content: makeChildren
        )
    }
}

@available(iOS 16.0, *)
private extension LayoutView {
    var children: [UIDefinition]? {
        if case let .list(content, _) = uiDefinition.component {
            content.children
        } else if case let .button(content, _) = uiDefinition.component {
            content.children
        } else {
            uiDefinition.children
        }
    }
	
    @ViewBuilder
    func makeChildren() -> some View {
        if let children {
            switch uiDefinition.component {
            case let .row(props): makeRow(children: children, props: props)
            case let .column(props): makeColumn(children: children, props: props)
            case let .selectionGroup(props): makeSelectable(children: children, props: props)
            default: ForEach(children.indices, id: \.self) { makeLayoutView(children: children, index: $0) }
            }
        }
    }
    
    @ViewBuilder
    func makeSelectable(children: [UIDefinition], props: SelectionGroupProps) -> some View {
        let content = { makeChildrenLayoutView(children: children, onTap: { onTapSelectable(child: $0) }) }
        if props.distribution == .vertical {
            VStack(content: content)
        } else {
            HStack(content: content)
        }
    }
    
    func makeChildrenLayoutView(children: [UIDefinition], onTap: ((UIDefinition) -> Void)? = nil) -> some View {
        ForEach(children.indices, id: \.self) { index in
            makeLayoutView(children: children, index: index)
                .allowsHitTesting(false)
                .overlay(
                    Rectangle().fill(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { onTap?(children[index]) }
                )
        }
    }
    
    func makeRow(children: [UIDefinition], props: RowProps) -> some View {
        HStack(alignment: props.verticalAlignment, spacing: 0) {
            makeRowStack(children: children, props: props)
        }
        .environment(\.flexAxis, .row)
        .environment(\.flexCrossAxisStretch, props.alignItems == .stretch)
        .padding(props.padding?.string.map(resolveSpacing) ?? .zero)
        .background(props.backgroundColor.map(resolveColor))
        .cornerRadius(props.borderRadius ?? 0)
    }
    
    func makeRowStack(children: [UIDefinition], props: RowProps) -> some View {
        HStack(spacing: props.spacing?.string.map(resolveSpacing)) {
            makeStackContent(children: children, props: props)
        }
        .frame(
            maxWidth: props.width(),
            maxHeight: props.height(),
            alignment: props.frameAlignment
        )
    }
    
    func makeColumn(children: [UIDefinition], props: ColumnProps) -> some View {
        VStack(alignment: props.horizontalAlignment, spacing: 0) {
            makeColumnStack(children: children, props: props)
        }
        .environment(\.flexCrossAxisStretch, props.alignItems == .stretch)
        .environment(\.flexAxis, .column)
        .padding(props.padding?.string.map(resolveSpacing) ?? .zero)
        .background(props.backgroundColor.map(resolveColor))
        .cornerRadius(props.borderRadius ?? 0)
    }
    
    func makeColumnStack(children: [UIDefinition], props: ColumnProps) -> some View {
        VStack(spacing: props.spacing?.string.map(resolveSpacing)) {
            makeStackContent(children: children, props: props)
        }
        .frame(
            maxWidth: props.width(),
            maxHeight: props.height(),
            alignment: props.frameAlignment
        )
    }
    
    func makeStackContent<P: Props>(children: [UIDefinition], props: P) -> some View {
        Group {
            if props.justifyContent == .spaceBetween {
                makeSpaceBetween(children: children)
            } else {
                makeLayoutViews(children: children)
            }
        }
    }
       
    func makeSpaceBetween(children: [UIDefinition]) -> some View {
        ForEach(children.indices, id: \.self) { index in
            makeLayoutView(children: children, index: index)
            if index < children.count - 1 { Spacer() }
        }
    }
    
    func makeLayoutViews(children: [UIDefinition]) -> some View {
        ForEach(children.indices, id: \.self) { index in
            makeLayoutView(children: children, index: index)
        }
    }

    func onTapSelectable(child: UIDefinition) {
        guard let id = uiDefinition.componentID else { unrecoverableError(.unexpectedNilComponentID) }
        guard
            case let .selectionOption(props) = child.component,
            let selectable = uiDefinition.component.selectable else {
            fatalError()
        }
        let newSet: CodableValue = selectable.mode == .single
            ? .array([.string(props.value)])
            : .array(Array(selectable.values.toggled(props.value).map(CodableValue.string)))
//        viewModel.applyEvent(.input(id: id, value: newSet, type: .onChange), screenID: screenID)
    }
	
    func makeLayoutView(children: [UIDefinition], index: Int) -> some View {
        LayoutView(focusedFieldID: focusedFieldID, uiDefinition: children[index], screenID: screenID)
    }
}
