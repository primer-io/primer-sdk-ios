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
    
    func initialize(schema: String, context: String, state: String) -> String {
        setObject(schema, forKey: "__schema")
        setObject(state, forKey: "__state")
        setObject(context, forKey: "__context")
        
        return """
        (async () => {
            try {
                const processor = await StateProcessor.createStateProcessor(__schema, JSON.parse(__context));
                const result = await processor.initialize(JSON.parse(__state));
                onInitializeResult(JSON.stringify(result));
            } catch (e) {
                onInitializeResult(JSON.stringify({ error: e.toString() }));
            }
        })();
        """
    }
    
    func eventScript(schema: String, context: String, state: String, event: String) -> String {
        setObject(schema, forKey: "__schema")
        setObject(state, forKey: "__state")
        setObject(event, forKey: "__event")
        setObject(context, forKey: "__context")
        
        return """
        (async () => {
            try {
                const processor = await StateProcessor.createStateProcessor(__schema, JSON.parse(__context));
                const result = await processor.applyEvent(JSON.parse(__state), JSON.parse(__event));
                onProcessFieldResult(JSON.stringify(result));
            } catch (e) {
                onProcessFieldResult(JSON.stringify({ error: e.toString() }));
            }
        })();
        """
    }
    
    func resultScript(
        schema: String,
        context: String,
        actionId: String,
        state: String,
        outcome: String,
        data: String?
    ) -> String {
        setObject(schema, forKey: "__schema")
        setObject(context, forKey: "__context")
        setObject(state, forKey: "__state")
        setObject(outcome, forKey: "__outcome")
        setObject(data as Any, forKey: "__data")
        setObject(actionId, forKey: "__actionId")
        
        return """
        (async () => {
            try {
                const processor = await StateProcessor.createStateProcessor(__schema, JSON.parse(__context));
                const result = await processor.applyResult(JSON.parse(__state), __actionId, __outcome, __data);
                onExecuteActionResult(JSON.stringify(result));
            } catch (e) {
                onExecuteActionResult(JSON.stringify({ error: e.toString() }));
            }
        })();
        """
    }
    
    private func setObject(_ value: Any, forKey key: String) {
        context.setObject(value, forKeyedSubscript: key as NSString)
    }
}
