//
//  PrimerModifier.swift
//
//
//  Created on 18.06.2025.
//

import SwiftUI

/// A comprehensive modifier system for Primer components that matches Android's Modifier functionality.
/// This provides a chain-able, type-safe way to style and configure UI components.
@available(iOS 15.0, *)
public struct PrimerModifier {

    // MARK: - Internal Storage

    internal var modifiers: [ModifierType] = []

    // MARK: - Initialization

    /// Creates an empty modifier
    public init() {}

    // MARK: - Core Modifier Types

    internal enum ModifierType {
        // Layout Modifiers
        case fillMaxWidth(alignment: HorizontalAlignment)
        case fillMaxHeight(alignment: VerticalAlignment)
        case fillMaxSize
        case width(CGFloat)
        case height(CGFloat)
        case size(width: CGFloat, height: CGFloat)
        case padding(EdgeInsets)
        case margin(EdgeInsets)

        // Background & Appearance
        case background(Color)
        case backgroundGradient(Gradient, startPoint: UnitPoint, endPoint: UnitPoint)
        case cornerRadius(CGFloat)
        case border(Color, width: CGFloat)
        case shadow(color: Color, radius: CGFloat, offsetX: CGFloat, offsetY: CGFloat)
        case opacity(Double)

        // Interactive States
        case disabled(Bool)
        case loading(Bool)
        case selected(Bool)
        case pressed(Bool)

        // Typography (for text-containing components)
        case font(Font)
        case foregroundColor(Color)
        case textAlignment(TextAlignment)

        // Animation
        case animation(Animation)

        // Custom SwiftUI Modifier
        case custom(AnyViewModifier)
    }
}

// MARK: - Layout Modifiers

@available(iOS 15.0, *)
public extension PrimerModifier {

    /// Makes the component fill the maximum available width
    func fillMaxWidth(alignment: HorizontalAlignment = .center) -> PrimerModifier {
        var copy = self
        copy.modifiers.append(.fillMaxWidth(alignment: alignment))
        return copy
    }

    /// Makes the component fill the maximum available height
    func fillMaxHeight(alignment: VerticalAlignment = .center) -> PrimerModifier {
        var copy = self
        copy.modifiers.append(.fillMaxHeight(alignment: alignment))
        return copy
    }

    /// Makes the component fill all available space
    func fillMaxSize() -> PrimerModifier {
        var copy = self
        copy.modifiers.append(.fillMaxSize)
        return copy
    }

    /// Sets a specific width for the component
    func width(_ width: CGFloat) -> PrimerModifier {
        var copy = self
        copy.modifiers.append(.width(width))
        return copy
    }

    /// Sets a specific height for the component
    func height(_ height: CGFloat) -> PrimerModifier {
        var copy = self
        copy.modifiers.append(.height(height))
        return copy
    }

    /// Sets specific width and height for the component
    func size(width: CGFloat, height: CGFloat) -> PrimerModifier {
        var copy = self
        copy.modifiers.append(.size(width: width, height: height))
        return copy
    }

    /// Adds padding around the component
    func padding(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) -> PrimerModifier {
        var copy = self
        let insets: EdgeInsets
        if let length = length {
            switch edges {
            case .all:
                insets = EdgeInsets(top: length, leading: length, bottom: length, trailing: length)
            case .top:
                insets = EdgeInsets(top: length, leading: 0, bottom: 0, trailing: 0)
            case .bottom:
                insets = EdgeInsets(top: 0, leading: 0, bottom: length, trailing: 0)
            case .leading:
                insets = EdgeInsets(top: 0, leading: length, bottom: 0, trailing: 0)
            case .trailing:
                insets = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: length)
            case .horizontal:
                insets = EdgeInsets(top: 0, leading: length, bottom: 0, trailing: length)
            case .vertical:
                insets = EdgeInsets(top: length, leading: 0, bottom: length, trailing: 0)
            default:
                insets = EdgeInsets(top: length, leading: length, bottom: length, trailing: length)
            }
        } else {
            // Default padding
            let defaultPadding: CGFloat = 16
            insets = EdgeInsets(top: defaultPadding, leading: defaultPadding, bottom: defaultPadding, trailing: defaultPadding)
        }
        copy.modifiers.append(.padding(insets))
        return copy
    }

    /// Adds margin around the component (implemented as outer padding)
    func margin(_ edges: Edge.Set = .all, _ length: CGFloat = 8) -> PrimerModifier {
        var copy = self
        let insets: EdgeInsets
        switch edges {
        case .all:
            insets = EdgeInsets(top: length, leading: length, bottom: length, trailing: length)
        case .top:
            insets = EdgeInsets(top: length, leading: 0, bottom: 0, trailing: 0)
        case .bottom:
            insets = EdgeInsets(top: 0, leading: 0, bottom: length, trailing: 0)
        case .leading:
            insets = EdgeInsets(top: 0, leading: length, bottom: 0, trailing: 0)
        case .trailing:
            insets = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: length)
        case .horizontal:
            insets = EdgeInsets(top: 0, leading: length, bottom: 0, trailing: length)
        case .vertical:
            insets = EdgeInsets(top: length, leading: 0, bottom: length, trailing: 0)
        default:
            insets = EdgeInsets(top: length, leading: length, bottom: length, trailing: length)
        }
        copy.modifiers.append(.margin(insets))
        return copy
    }
}

// MARK: - Appearance Modifiers

@available(iOS 15.0, *)
public extension PrimerModifier {

    /// Sets the background color
    func background(_ color: Color) -> PrimerModifier {
        var copy = self
        copy.modifiers.append(.background(color))
        return copy
    }

    /// Sets a gradient background
    func backgroundGradient(
        _ gradient: Gradient,
        startPoint: UnitPoint = .topLeading,
        endPoint: UnitPoint = .bottomTrailing
    ) -> PrimerModifier {
        var copy = self
        copy.modifiers.append(.backgroundGradient(gradient, startPoint: startPoint, endPoint: endPoint))
        return copy
    }

    /// Sets corner radius
    func cornerRadius(_ radius: CGFloat) -> PrimerModifier {
        var copy = self
        copy.modifiers.append(.cornerRadius(radius))
        return copy
    }

    /// Adds a border
    func border(_ color: Color, width: CGFloat = 1) -> PrimerModifier {
        var copy = self
        copy.modifiers.append(.border(color, width: width))
        return copy
    }

    /// Adds a shadow
    func shadow(
        color: Color = .black.opacity(0.2),
        radius: CGFloat = 4,
        offsetX: CGFloat = 0,
        offsetY: CGFloat = 2
    ) -> PrimerModifier {
        var copy = self
        copy.modifiers.append(.shadow(color: color, radius: radius, offsetX: offsetX, offsetY: offsetY))
        return copy
    }

    /// Sets opacity
    func opacity(_ opacity: Double) -> PrimerModifier {
        var copy = self
        copy.modifiers.append(.opacity(opacity))
        return copy
    }
}

// MARK: - State Modifiers

@available(iOS 15.0, *)
public extension PrimerModifier {

    /// Sets disabled state
    func disabled(_ disabled: Bool = true) -> PrimerModifier {
        var copy = self
        copy.modifiers.append(.disabled(disabled))
        return copy
    }

    /// Sets loading state
    func loading(_ loading: Bool = true) -> PrimerModifier {
        var copy = self
        copy.modifiers.append(.loading(loading))
        return copy
    }

    /// Sets selected state
    func selected(_ selected: Bool = true) -> PrimerModifier {
        var copy = self
        copy.modifiers.append(.selected(selected))
        return copy
    }

    /// Sets pressed state
    func pressed(_ pressed: Bool = true) -> PrimerModifier {
        var copy = self
        copy.modifiers.append(.pressed(pressed))
        return copy
    }
}

// MARK: - Typography Modifiers

@available(iOS 15.0, *)
public extension PrimerModifier {

    /// Sets the font
    func font(_ font: Font) -> PrimerModifier {
        var copy = self
        copy.modifiers.append(.font(font))
        return copy
    }

    /// Sets the foreground color
    func foregroundColor(_ color: Color) -> PrimerModifier {
        var copy = self
        copy.modifiers.append(.foregroundColor(color))
        return copy
    }

    /// Sets text alignment
    func textAlignment(_ alignment: TextAlignment) -> PrimerModifier {
        var copy = self
        copy.modifiers.append(.textAlignment(alignment))
        return copy
    }
}

// MARK: - Animation Modifiers

@available(iOS 15.0, *)
public extension PrimerModifier {

    /// Adds animation
    func animation(_ animation: Animation) -> PrimerModifier {
        var copy = self
        copy.modifiers.append(.animation(animation))
        return copy
    }
}

// MARK: - Custom Modifiers

@available(iOS 15.0, *)
public extension PrimerModifier {

    /// Adds a custom SwiftUI ViewModifier
    func custom<M: ViewModifier>(_ modifier: M) -> PrimerModifier {
        var copy = self
        copy.modifiers.append(.custom(AnyViewModifier(modifier)))
        return copy
    }
}

// MARK: - Static Factory Methods (matches Android's Modifier.* pattern)

@available(iOS 15.0, *)
public extension PrimerModifier {

    /// Static factory for fill max width (matches Android's Modifier.fillMaxWidth())
    static func fillMaxWidth(alignment: HorizontalAlignment = .center) -> PrimerModifier {
        PrimerModifier().fillMaxWidth(alignment: alignment)
    }

    /// Static factory for fill max height (matches Android's Modifier.fillMaxHeight())
    static func fillMaxHeight(alignment: VerticalAlignment = .center) -> PrimerModifier {
        PrimerModifier().fillMaxHeight(alignment: alignment)
    }

    /// Static factory for fill max size (matches Android's Modifier.fillMaxSize())
    static func fillMaxSize() -> PrimerModifier {
        PrimerModifier().fillMaxSize()
    }

    /// Static factory for padding (matches Android's Modifier.padding())
    static func padding(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) -> PrimerModifier {
        PrimerModifier().padding(edges, length)
    }

    /// Static factory for size (matches Android's Modifier.size())
    static func size(width: CGFloat, height: CGFloat) -> PrimerModifier {
        PrimerModifier().size(width: width, height: height)
    }

    /// Static factory for background (matches Android's Modifier.background())
    static func background(_ color: Color) -> PrimerModifier {
        PrimerModifier().background(color)
    }
}

// MARK: - Helper Types

@available(iOS 15.0, *)
internal struct AnyViewModifier: ViewModifier {
    private let _body: (Content) -> AnyView

    init<M: ViewModifier>(_ modifier: M) {
        _body = { content in
            AnyView(content.modifier(modifier))
        }
    }

    func body(content: Content) -> some View {
        _body(content)
    }
}

// MARK: - View Extension for Applying PrimerModifier

@available(iOS 15.0, *)
public extension View {

    /// Applies a PrimerModifier to any SwiftUI view
    func primerModifier(_ modifier: PrimerModifier) -> some View {
        modifier.apply(to: self)
    }
}

// MARK: - PrimerModifier Application Logic

@available(iOS 15.0, *)
internal extension PrimerModifier {

    /// Applies all stored modifiers to a view
    func apply<V: View>(to view: V) -> some View {
        var modifiedView = AnyView(view)

        for modifier in modifiers {
            modifiedView = AnyView(applyModifier(modifier, to: modifiedView))
        }

        return modifiedView
    }

    /// Applies a single modifier to a view
    @ViewBuilder
    private func applyModifier(_ modifier: ModifierType, to view: AnyView) -> some View {
        switch modifier {
        // Layout Modifiers
        case .fillMaxWidth,
             .fillMaxHeight,
             .fillMaxSize,
             .width,
             .height,
             .size,
             .padding,
             .margin:
            applyLayoutModifier(modifier, to: view)

        // Appearance Modifiers
        case .background,
             .backgroundGradient,
             .cornerRadius,
             .border,
             .shadow,
             .opacity:
            applyAppearanceModifier(modifier, to: view)

        // State Modifiers
        case .disabled,
             .loading,
             .selected,
             .pressed:
            applyStateModifier(modifier, to: view)

        // Typography Modifiers
        case .font,
             .foregroundColor,
             .textAlignment:
            applyTypographyModifier(modifier, to: view)

        // Animation & Custom Modifiers
        case .animation,
             .custom:
            applySpecialModifier(modifier, to: view)
        }
    }

    /// Applies layout-specific modifiers
    @ViewBuilder
    private func applyLayoutModifier(_ modifier: ModifierType, to view: AnyView) -> some View {
        switch modifier {
        case .fillMaxWidth(let alignment):
            view.frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))
        case .fillMaxHeight(let alignment):
            view.frame(maxHeight: .infinity, alignment: Alignment(horizontal: .center, vertical: alignment))
        case .fillMaxSize:
            view.frame(maxWidth: .infinity, maxHeight: .infinity)
        case .width(let width):
            view.frame(width: width)
        case .height(let height):
            view.frame(height: height)
        case .size(let width, let height):
            view.frame(width: width, height: height)
        case .padding(let insets):
            view.padding(insets)
        case .margin(let insets):
            view.padding(insets) // Margin implemented as padding
        default:
            view // Should never reach here due to the parent switch
        }
    }

    /// Applies appearance-specific modifiers
    @ViewBuilder
    private func applyAppearanceModifier(_ modifier: ModifierType, to view: AnyView) -> some View {
        switch modifier {
        case .background(let color):
            view.background(color)
        case .backgroundGradient(let gradient, let startPoint, let endPoint):
            view.background(
                LinearGradient(gradient: gradient, startPoint: startPoint, endPoint: endPoint)
            )
        case .cornerRadius(let radius):
            view.cornerRadius(radius)
        case .border(let color, let width):
            view.overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(color, lineWidth: width)
            )
        case .shadow(let color, let radius, let offsetX, let offsetY):
            view.shadow(color: color, radius: radius, x: offsetX, y: offsetY)
        case .opacity(let opacity):
            view.opacity(opacity)
        default:
            view // Should never reach here due to the parent switch
        }
    }

    /// Applies state-specific modifiers
    @ViewBuilder
    private func applyStateModifier(_ modifier: ModifierType, to view: AnyView) -> some View {
        switch modifier {
        case .disabled(let disabled):
            view.disabled(disabled)
        case .loading(let loading):
            if loading {
                view.overlay(
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                )
            } else {
                view
            }
        case .selected(let selected):
            if selected {
                view.overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.blue, lineWidth: 2)
                )
            } else {
                view
            }
        case .pressed(let pressed):
            view.scaleEffect(pressed ? 0.98 : 1.0)
        default:
            view // Should never reach here due to the parent switch
        }
    }

    /// Applies typography-specific modifiers
    @ViewBuilder
    private func applyTypographyModifier(_ modifier: ModifierType, to view: AnyView) -> some View {
        switch modifier {
        case .font(let font):
            view.font(font)
        case .foregroundColor(let color):
            view.foregroundColor(color)
        case .textAlignment(let alignment):
            view.multilineTextAlignment(alignment)
        default:
            view // Should never reach here due to the parent switch
        }
    }

    /// Applies animation and custom modifiers
    @ViewBuilder
    private func applySpecialModifier(_ modifier: ModifierType, to view: AnyView) -> some View {
        switch modifier {
        case .animation(let animation):
            view.animation(animation, value: UUID()) // Note: Value needed for SwiftUI animation
        case .custom(let customModifier):
            view.modifier(customModifier)
        default:
            view // Should never reach here due to the parent switch
        }
    }
}
