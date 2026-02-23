//
//  StepDomain.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

public enum StepDomain: String, Decodable {
    case httpRequest = "http.request"
    case uiRender = "ui.render"
    case urlOpen = "url.open"
    case analyticsLog = "analytics.log"
}
