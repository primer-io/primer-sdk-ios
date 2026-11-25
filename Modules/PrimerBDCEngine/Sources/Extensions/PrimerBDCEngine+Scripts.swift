//
//  PrimerBDCEngine+Scripts.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import JavaScriptCore
import PrimerFoundation

extension PrimerBDCEngine {
    var instantiate: String {
        """
        (async function() {
            try {
                const u8 = new Uint8Array(wasmBytes);
                await wasm_bindgen(u8.buffer);
                globalThis.__wasmExports = wasm_bindgen;
                onWASMReady();
            } catch (e) {
                onLoadFailed(JSON.stringify({ error: e.toString() }));
            }
        })();
        """
    }

    func call(_ script: EngineScript, id: Int) -> String {
        let reply = "(reply) => onScriptReply(\(id), reply)"
        let failure = "(e) => onScriptReply(\(id), JSON.stringify({ error: String(e) }))"
        return """
        (async ({ \(script.arguments.keys.sorted().joined(separator: ", ")) }) => {
        \(script.body)
        })(__arguments).then(\(reply), \(failure));
        """
    }
}
