//
//  DismissalMechanism.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

/// Specifies how users can dismiss the checkout modal.
///
/// You can enable multiple dismissal mechanisms by passing an array to `PrimerUIOptions`.
/// For example, `[.gestures, .closeButton]` allows both swipe gestures and a close button.
public enum DismissalMechanism: String, Codable {
    /// Allow dismissal via swipe-down gestures on the modal.
    case gestures = "GESTURES"

    /// Display a close button in the navigation area.
    case closeButton = "CLOSE_BUTTON"
}