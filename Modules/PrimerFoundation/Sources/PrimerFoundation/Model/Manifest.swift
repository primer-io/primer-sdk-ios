//
//  Manifest.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@_spi(PrimerInternal)
public struct Manifest: Decodable {
    
    public let stateProcessorContainer: URLContainer
    public let celWrapperJSURLContainer: URLContainer
    public let celWrapperWASMURLContainer: BrotliContainer
    
    public init(from decoder: Decoder) throws {
        let inner = try InnerManifest(from: decoder)
        stateProcessorContainer = inner.stateProcessor.umd
        celWrapperJSURLContainer = inner.cel.noModules.js
        celWrapperWASMURLContainer = inner.cel.noModules.wasm
    }
}

public struct SignedManifest: Decodable {
    public let signature: String
    public let manifest: Data
}

public struct URLContainer: Decodable {
    public let sha256: String
    public let url: String
}

public struct BrotliContainer: Decodable {
    public let sha256: String
    public let br: String
}

private struct InnerManifest: Decodable {
    let stateProcessor: StateProcessor
    let cel: CEL
}

private struct StateProcessor: Decodable {
    let umd: URLContainer
}

private struct CEL: Decodable {
    let noModules: NoModules
}

private struct NoModules: Decodable {
    let js: URLContainer
    let wasm: BrotliContainer
}
