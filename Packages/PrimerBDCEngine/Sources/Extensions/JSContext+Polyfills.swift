//
//  JSContext+Polyfills.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import JavaScriptCore.JSContext

extension JSContext {
    
    var consolePolyfill: String {
        """
        (function setupConsoleHooks() {
          globalThis.console = {
            log: function(msg) {
              if (typeof consoleLog === "function") consoleLog(String(msg));
            },
            warn: function(msg) {
              if (typeof consoleError === "function") consoleError("Warning: " + String(msg));
            },
            error: function(msg) {
              if (typeof consoleError === "function") consoleError("Error: " + String(msg));
            }
          };
        })();
        """
    }
    
    var textCodecPolyfill: String {
      """
      function utf8ToString(buf) {
        let str = \"\", i = 0;
        while (i < buf.length) {
          const c = buf[i++];
          if (c < 128) str += String.fromCharCode(c);
          else if (c > 191 && c < 224) {
            const c2 = buf[i++];
            str += String.fromCharCode(((c & 31) << 6) | (c2 & 63));
          } else {
            const c2 = buf[i++];
            const c3 = buf[i++];
            str += String.fromCharCode(
              ((c & 15) << 12) |
              ((c2 & 63) << 6) |
              (c3 & 63)
            );
          }
        }
        return str;
      }
      class TextDecoder { decode(buffer) { return utf8ToString(new Uint8Array(buffer)); } }
      class TextEncoder {
        encode(str) {
          // a quick-and-dirty UTF-8 encoder...
          const bytes = [];
          for (let i = 0; i < str.length; i++) {
            const code = str.charCodeAt(i);
            if (code < 0x80) bytes.push(code);
            else if (code < 0x800) {
              bytes.push(0xc0 | (code >> 6), 0x80 | (code & 0x3f));
            } else {
              bytes.push(
                0xe0 | (code >> 12),
                0x80 | ((code >> 6) & 0x3f),
                0x80 | (code & 0x3f)
              );
            }
          }
          return new Uint8Array(bytes);
        }
      }
      globalThis.TextDecoder = TextDecoder;
      globalThis.TextEncoder = TextEncoder;
      """
    }
    
}
