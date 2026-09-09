//
//  ComponentView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation
import SwiftUI

struct UIComponentArgs {
    let fieldID: String?
    let component: Component
}

@available(iOS 16.0, *)
struct ComponentView<C: View>: View {
    @EnvironmentObject private var viewModel: SDUIViewModel
    @Environment(\.flexCrossAxisStretch) private var stretch
    @Environment(\.flexAxis) private var axis
    
    private let focusedFieldID: FocusState<String?>.Binding
    private let componentArgs: UIComponentArgs
    private let visible: Bool
    private let slots: Slots?
    private let content: (() -> C)
    
    init(
        component: Component,
        fieldID: String?,
        focusedFieldID: FocusState<String?>.Binding,
        visible: CodableValue?,
        slots: Slots?,
        content: @escaping (() -> C)
    ) {
        componentArgs = UIComponentArgs(fieldID: fieldID, component: component)
        self.content = content
        self.slots = slots
        self.focusedFieldID = focusedFieldID
        self.visible = switch visible {
        case let .bool(bool): bool
        case .string: false
        default: true
        }
    }
    
    var body: some View {
        if case .spacer = componentArgs.component {
            Spacer()
        } else {
            makeComponentView()
        }
    }
}

@available(iOS 16.0, *)
private extension ComponentView {
    func updateState(with input: String) {
        guard let componentID = componentArgs.fieldID else { return unrecoverableError(.unexpectedNilComponentID) }
        viewModel.applyEvent(.input(id: componentID, value: .string(input), type: .onChange))
    }
    
    func applyClick() {
        guard let componentID = componentArgs.fieldID else { return unrecoverableError(.unexpectedNilComponentID) }
        withAnimation { viewModel.applyEvent(.click(id: componentID)) }
    }
}

@available(iOS 16.0, *)
private extension ComponentView {
    
    @ViewBuilder
    func makeComponentView() -> some View {
        if visible {
            switch componentArgs.component {
            case let .box(props): makeBox(props: props)
            case let .button(_, props): makeButtonView(props: props)
            case .column, .row: content() // see LayoutView
            case let .checkbox(props): makeCheckboxView(props: props)
            case let .radioButton(props): makeRadioButtonView(props: props)
            case let .container(props): makeContainer(props: props)
            case .list: List(content: content)
            case let .image(props): makeImage(props: props)
            case let .progressIndicator(props): makeProgressView(props: props)
            case let .text(props): makeTextView(props: props)
            case let .textField(props): makeTextFieldView(props: props)
            case .spacer: Spacer()
            case let .custom(type, props): ProviderComponentView(type: type, props: props).id(props)
            default: content()
            }
        }
    }
    
    func makeButtonView(props: ButtonProps) -> some View {
        Button(action: applyClick) {
            content()
                .frame(maxWidth: props.width())
                .padding(props.padding?.string.map(resolveSpacing) ?? .zero)
        }
        .frame(maxWidth: props.width(), maxHeight: props.height())
        .background(props.backgroundColor.map(resolveColor))
        .cornerRadius(props.borderRadius ?? 0)
        .disabled(!props.enabled)
        .buttonStyle(.plain)
    }
    
    func makeBox(props: BoxProps) -> some View {
        ZStack(content: content)
            .frame(
                maxWidth: (stretch && axis == .column) ? .infinity : nil,
                maxHeight: (stretch && axis == .row) ? .infinity : nil
            )
            .background(props.backgroundColor.map(resolveColor))
    }
    
    func makeContainer(props: ContainerProps) -> some View {
        VStack(content: content)
            .padding(props.padding)
            .background(props.backgroundColor.map(resolveColor))
            .cornerRadius(props.borderRadius ?? 0)
    }
	
    @ViewBuilder
    func makeImage(props: ImageProps) -> some View {
        AsyncImage(
            url: URL(string: props.source),
            content: { makeAsyncImageContent(image: $0, props: props) },
            placeholder: {
                if let fallback = props.fallback {
                    AsyncImage(
                        url: URL(string: fallback),
                        content: { makeAsyncImageContent(image: $0, props: props) },
                        placeholder: ProgressView.init
                    )
                } else {
                    ProgressView()
                }
            }
        )
    }
	
    func makeAsyncImageContent(image: Image, props: ImageProps) -> some View {
        Group {
            if let contentMode = props.contentMode?.callAsFunction() {
                image.resizable().aspectRatio(contentMode: contentMode)
            } else {
                image.resizable()
            }
        }.frame(width: props.width(), height: props.height())
    }
    
    func makeTextFieldView(props: TextFieldProps) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                ForEach((slots?.filter { $0.key == "prefix" }) ?? [], id: \.value) {
                    LayoutView(focusedFieldID: focusedFieldID, uiDefinition: $0.value)
                }
                TextFieldView(
                    label: props.label,
                    placeholder: props.placeholder ?? "",
                    text: props.value,
                    autoComplete: props.autoComplete,
                    keyboardType: props.keyboardType,
                    onChange: updateState(with:)
                )
                .focused(focusedFieldID, equals: componentArgs.fieldID)

                ForEach((slots?.filter { $0.key == "suffix" }) ?? [], id: \.value) {
                    LayoutView(focusedFieldID: focusedFieldID, uiDefinition: $0.value)
                }
            }
        }
    }
    
    func makeTextView(props: TextProps) -> some View {
        TextView(text: props.text)
            .font(props.textStyle.map(resolveFont))
            .foregroundColor(props.color.map(resolveColor))
            .multilineTextAlignment(props.textAlign())
    }
	
    func makeCheckboxView(props: CheckboxProps) -> some View {
        UISwitchRepresentable(isOn: props.selected)
    }
	
    func makeRadioButtonView(props: RadioButtonProps) -> some View {
        RadioButtonCircle(isSelected: props.selected ?? false, color: .primary) // TODO: Color
    }
	
    func makeProgressView(props: ProgressIndicatorProps) -> some View {
        ProgressView().controlSize(props.size())
    }
}
