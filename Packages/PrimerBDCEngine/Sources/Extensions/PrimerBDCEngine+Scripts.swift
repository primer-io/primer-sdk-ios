//
//  PrimerBDCEngine+Scripts.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import JavaScriptCore
import PrimerFoundation
import PrimerStepResolver

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
    
    func initialize(schema: String, state: String) -> String {
        setObject(schema, forKey: "__schema")
        setObject(state, forKey: "__state")
        setObject("TODO:", forKey: "__screenId") // Not ready yet
        
        return """
        (async () => {
            try {
                const processor = await StateProcessor.createStateProcessor(__schema,  __screenId);
                const result = await processor.triggerInitialWorkflows(JSON.parse(__state));
                onInitializeResult(JSON.stringify(result));
            } catch (e) {
                onInitializeResult(JSON.stringify({ error: e.toString() }));
            }
        })();
        """
    }
    
    func eventsScript(
        schema: String,
        screenId: String,
        state: String,
        event: Event
    ) -> String {
        setObject(schema, forKey: "__schema")
        setObject(state, forKey: "__state")
        setObject(screenId, forKey: "__screenId")
        
        setObject(event.eventType, forKey: "__eventType")
        setObject(event.id, forKey: "__eventId" )
        setObject(event.value ?? JSValue(undefinedIn: context), forKey: "__eventValue")
        
        return """
        (async () => {
            try {
                const dict = {
                    type: __eventType,
                    id: __eventId,
                    ...(__eventValue === undefined ? {} : { value: __eventValue })
                };
                const processor = await StateProcessor.createStateProcessor(__schema, __screenId);
                const result = await processor.applyEvent(JSON.parse(__state), dict);
                onProcessFieldResult(JSON.stringify(result));
            } catch (e) {
                onProcessFieldResult(JSON.stringify({ error: e.toString() }));
            }
        })();
        """
    }
    
    func actionsScript(
        schema: String,
        screenId: String,
        state: String,
        workflowId: String,
        stepId: String,
        response: String?
    ) -> String {
        setObject(schema, forKey: "__schema")
        setObject(state, forKey: "__state")
        setObject(screenId, forKey: "__screenId")
        
        setObject(workflowId, forKey: "__workflowId")
        setObject(stepId, forKey: "__stepId")
        setObject(response, forKey: "__response")
        
        return """
        (async () => {
            try {
                const processor = await StateProcessor.createStateProcessor(__schema, __screenId);
                const result = await processor.applyWorkflowStepResponse(JSON.parse(__state), __workflowId, __stepId, __response);
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
