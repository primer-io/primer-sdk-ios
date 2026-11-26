//
//  PrimerBDCWebViewEngine+Scripts.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@available(iOS 15.0, *)
extension PrimerBDCWebViewEngine {
    var nonNilCompletionValue: String { "\n;true" }

    var instantiateScript: String {
        """
        const bytes = Uint8Array.from(atob(wasm), (character) => character.charCodeAt(0));
        await wasm_bindgen(bytes.buffer);
        globalThis.__wasmExports = wasm_bindgen;
        return true;
        """
    }
}
