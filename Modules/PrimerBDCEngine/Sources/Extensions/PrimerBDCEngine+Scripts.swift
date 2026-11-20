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
    
    private var flowStepOf: String {
        """
        const flowStepOf = (result) => {
            const answer = result.answer;
            const reply = !answer ? {} : {
                reply: answer.handled ? { kind: 'handled', value: answer.reply } : { kind: 'unhandled' },
            };
            if (result.error) return { kind: 'failed', error: result.error, ...reply };
            if (result.terminal) return { kind: 'finished', outcome: result.terminal.outcome, ...reply };
            const shown = { state: result.newState, layers: result.renderStack };
            if (result.action) return { kind: 'runAction', ...shown, action: result.action, ...reply };
            return { kind: 'awaitInput', ...shown, ...reply };
        };
        """
    }

    func startFlowScript(schema: String, context: String, state: String) -> String {
        setObject(schema, forKey: "__schema")
        setObject(state, forKey: "__state")
        setObject(context, forKey: "__context")
        
        return """
        (async () => {
            try {
                \(flowStepOf)
                const processor = await StateProcessor.createStateProcessor(__schema, JSON.parse(__context));
                const state = JSON.parse(__state);
                const step = typeof processor.startFlow === 'function'
                    ? await processor.startFlow(state)
                    : flowStepOf(await processor.initialize(state));
                onInitializeResult(JSON.stringify(step));
            } catch (e) {
                onInitializeResult(JSON.stringify({ error: e.toString() }));
            }
        })();
        """
    }
    
    func handleEventScript(schema: String, context: String, state: String, event: String) -> String {
        setObject(schema, forKey: "__schema")
        setObject(state, forKey: "__state")
        setObject(event, forKey: "__event")
        setObject(context, forKey: "__context")
        
        return """
        (async () => {
            try {
                \(flowStepOf)
                const processor = await StateProcessor.createStateProcessor(__schema, JSON.parse(__context));
                const state = JSON.parse(__state);
                const event = JSON.parse(__event);
                const step = typeof processor.handleEvent === 'function'
                    ? await processor.handleEvent(state, event)
                    : flowStepOf(await processor.applyEvent(state, event));
                onProcessFieldResult(JSON.stringify(step));
            } catch (e) {
                onProcessFieldResult(JSON.stringify({ error: e.toString() }));
            }
        })();
        """
    }
    
    func handleActionResultScript(
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
        setObject(data ?? "{}", forKey: "__data")
        setObject(actionId, forKey: "__actionId")
        
        return """
        (async () => {
            try {
                \(flowStepOf)
                const processor = await StateProcessor.createStateProcessor(__schema, JSON.parse(__context));
                const state = JSON.parse(__state);
                const data = JSON.parse(__data);
                const step = typeof processor.handleActionResult === 'function'
                    ? await processor.handleActionResult(state, { actionId: __actionId, outcome: __outcome, data })
                    : flowStepOf(await processor.applyResult(state, __actionId, __outcome, data));
                onExecuteActionResult(JSON.stringify(step));
            } catch (e) {
                onExecuteActionResult(JSON.stringify({ error: e.toString() }));
            }
        })();
        """
    }

    func probesToRunScript(items: String, client: String) -> String {
        setObject(items, forKey: "__items")
        setObject(client, forKey: "__client")
        
        return """
        (async () => {
            try {
                if (typeof StateProcessor.probesToRun !== 'function') {
                    onProbesToRunResult(JSON.stringify({ result: [] }));
                    return;
                }
                const result = await StateProcessor.probesToRun(JSON.parse(__items), JSON.parse(__client));
                onProbesToRunResult(JSON.stringify({ result }));
            } catch (e) {
                onProbesToRunResult(JSON.stringify({ error: e.toString() }));
            }
        })();
        """
    }

    func checkClientRequirementsScript(items: String, client: String, results: String) -> String {
        setObject(items, forKey: "__items")
        setObject(client, forKey: "__client")
        setObject(results, forKey: "__results")
        
        return """
        (async () => {
            try {
                const client = JSON.parse(__client);
                const results = JSON.parse(__results);
                const result = {};
                for (const item of JSON.parse(__items)) {
                    result[item.id] = await StateProcessor.checkClientRequirements(item.clientRequirements, client, results);
                }
                onCheckClientRequirementsResult(JSON.stringify({ result }));
            } catch (e) {
                onCheckClientRequirementsResult(JSON.stringify({ error: e.toString() }));
            }
        })();
        """
    }

    private func setObject(_ value: Any, forKey key: String) {
        context.setObject(value, forKeyedSubscript: key as NSString)
    }
}
