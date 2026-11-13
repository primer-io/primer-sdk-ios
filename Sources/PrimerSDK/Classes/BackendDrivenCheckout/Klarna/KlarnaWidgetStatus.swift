//
//  KlarnaWidgetStatus.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation

enum KlarnaWidgetStatus: Equatable {
    case ready(instanceId: String)
    case unavailable(KlarnaWidgetError? = nil)
    case failed(KlarnaWidgetError)

    var type: String {
        switch self {
        case .ready: "ready"
        case .unavailable: "unavailable"
        case .failed: "failed"
        }
    }

    var data: [String: CodableValue] {
        switch self {
        case let .ready(instanceId):
            ["show_form": .bool(true), "instanceId": .string(instanceId)]
        case let .unavailable(error):
            (error?.data ?? [:]).merging(["show_form": .bool(false)]) { $1 }
        case let .failed(error):
            error.data
        }
    }
}

struct KlarnaWidgetError: Equatable {
    let code: String
    let message: String

    var data: [String: CodableValue] {
        ["code": .string(code), "message": .string(message)]
    }
}
