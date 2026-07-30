//
//  ContentView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

private let initialURL = "https://primer-sdk-demo-git-feat-paypal-app-switch-primer-io.vercel.app/primer-checkout?settings=eyJjbGllbnRTZXNzaW9uQ29uZmlnIjp7ImN1c3RvbWVySWQiOiJjdXN0b21lci0xMjM0Iiwib3JkZXJJZCI6Ijk2NjY0IiwiYW1vdW50IjoxLCJjdXJyZW5jeUNvZGUiOiJVU0QiLCJtZXRhZGF0YSI6eyJwYXltZW50TWV0aG9kIjoicGF5cGFsIiwic2NlbmFyaW8iOiJQQVlQQUwifSwib3JkZXIiOnsiY291bnRyeUNvZGUiOiJVUyIsImxpbmVJdGVtcyI6W3siaXRlbUlkIjoicHJpbWVyLWhvb2RpZS1ncmF5IiwiZGVzY3JpcHRpb24iOiJQcmltZXIgSG9vZGllIiwiYW1vdW50IjoxLCJxdWFudGl0eSI6MX1dfSwiY3VzdG9tZXIiOnsiZW1haWxBZGRyZXNzIjoiam9obkBwcmltZXIuaW8iLCJtb2JpbGVOdW1iZXIiOiIwODIxMjM0NTY3IiwiZmlyc3ROYW1lIjoiSm9obiIsImxhc3ROYW1lIjoiU21pdGgiLCJiaWxsaW5nQWRkcmVzcyI6eyJmaXJzdE5hbWUiOiJKb2huIiwibGFzdE5hbWUiOiJTbWl0aCIsInBvc3RhbENvZGUiOiJFQzJBIDRUUCIsImFkZHJlc3NMaW5lMSI6IjEyMyBGYWtlIFN0IiwiY291bnRyeUNvZGUiOiJVUyIsImNpdHkiOiJMb25kb24iLCJzdGF0ZSI6IkxvbmRvbiJ9LCJzaGlwcGluZ0FkZHJlc3MiOnsiZmlyc3ROYW1lIjoiSm9obiIsImxhc3ROYW1lIjoiU21pdGgiLCJwb3N0YWxDb2RlIjoiRUMyQSA0VFAiLCJhZGRyZXNzTGluZTEiOiIxMjMgRmFrZSBTdCIsImNvdW50cnlDb2RlIjoiVVMiLCJjaXR5IjoiTG9uZG9uIiwic3RhdGUiOiJMb25kb24ifSwibmF0aW9uYWxEb2N1bWVudElkIjoiOTAxMTIxMTIzNDU2NyJ9LCJwYXltZW50TWV0aG9kIjp7InZhdWx0T25TdWNjZXNzIjp0cnVlLCJ2YXVsdE9uM0RTIjpmYWxzZSwidmF1bHRPbkFncmVlbWVudCI6ZmFsc2UsIm9yZGVyZWRBbGxvd2VkQ2FyZE5ldHdvcmtzIjpbIlZJU0EiLCJNQVNURVJDQVJEIiwiQU1FWCIsIk1BRVNUUk8iLCJVTklPTlBBWSIsIkNBUlRFU19CQU5DQUlSRVMiLCJEQU5LT1JUIiwiRElORVJTX0NMVUIiLCJESVNDT1ZFUiIsIkVGVFBPUyIsIkVOUk9VVEUiLCJFTE8iLCJISVBFUiIsIklOVEVSQUMiLCJKQ0IiLCJNSVIiLCJQUklNRVJfVEVTVCIsIk9USEVSIl19LCJhcHByb3ZhbE1vZGUiOiJBVVRPIn0sImNsaWVudE9wdGlvbnMiOnsibG9jYWxlIjoiZW4iLCJjYXJkIjp7InByZWZlcnJlZEZsb3ciOiJFTUJFRERFRF9JTl9IT01FIn0sImRpcmVjdERlYml0Ijp7ImN1c3RvbWVyQ291bnRyeUNvZGUiOiJGUiIsImNvbXBhbnlOYW1lIjoiUHJpbWVyIEFQSSBMVEQiLCJjb21wYW55QWRkcmVzcyI6IjEyMyBGYWtlIFN0LCBMb25kb24sIEVDMkEgOFhZIn0sInJlZGlyZWN0Ijp7ImZvcmNlUmVkaXJlY3QiOmZhbHNlfSwiZ29vZ2xlUGF5Ijp7ImNhcHR1cmVCaWxsaW5nQWRkcmVzcyI6dHJ1ZX19LCJhcGlDb25maWciOnsiYXBpS2V5IjoiNTVmOWJmNmQtNzUzMy00Y2M3LWFiYTEtYmNkZDdkMTBlNGViIiwiYXBpVmVyc2lvbiI6IjIuNCIsImVudiI6IkNVU1RPTV9ERVYifSwiaGVhZGxlc3NPcHRpb25zIjp7ImxvY2FsZSI6ImVuIGZkc2YiLCJyZWRpcmVjdCI6eyJmb3JjZVJlZGlyZWN0IjpmYWxzZSwicmV0dXJuVXJsIjoiaHR0cHM6Ly9zZGstZGVtby5wcmltZXIuaW8vdjItbGF0ZXN0L2hlYWRsZXNzIn19LCJwcmltZXJDaGVja291dE9wdGlvbnMiOnsic2RrQ29yZSI6dHJ1ZSwidmF1bHQiOnsiZW5hYmxlZCI6dHJ1ZX0sInBheXBhbCI6eyJhcHBTd2l0Y2giOnsiZW5hYmxlZCI6dHJ1ZSwicmV0dXJuVXJsIjoiaHR0cHM6Ly9wcmltZXItc2RrLWRlbW8tZ2l0LWZlYXQtcGF5cGFsLWFwcC1zd2l0Y2gtcHJpbWVyLWlvLnZlcmNlbC5hcHAvcHJpbWVyLWNoZWNrb3V0In19LCJyZWRpcmVjdCI6eyJyZXR1cm5VcmwiOiJodHRwczovL3Nkay1kZW1vLnByaW1lci5pby9wcmltZXItY2hlY2tvdXQifX19&scenario=PrimerPayPalAppSwitchDemo"

public struct ContentView: View {
    @Binding var incomingURL: URL?
    @State private var urlText: String = initialURL
    @State private var currentURL: URL? = URL(string: initialURL)
    @State private var logs: [String] = []
    @State private var showLogs: Bool = false
    @State private var returnURL: URL?
    
    public init() {
        _incomingURL = .constant(nil)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // URL bar
            HStack {
                TextField("Enter URL", text: $urlText)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                    .onSubmit { loadURL() }

                Button("Go") { loadURL() }
                    .buttonStyle(.borderedProminent)
            }
            .padding(8)

            // WebView
            WebView(url: currentURL, logs: $logs, returnURL: $returnURL)
                .ignoresSafeArea(edges: .bottom)

            // Log toggle bar
            Button {
                withAnimation { showLogs.toggle() }
            } label: {
                HStack {
                    Image(systemName: "list.bullet.rectangle")
                    Text("Logs (\(logs.count))")
                    Spacer()
                    Image(systemName: showLogs ? "chevron.down" : "chevron.up")
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray5))
            }

            // Log panel
            if showLogs {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(logs.enumerated()), id: \.offset) { index, log in
                                Text(log)
                                    .font(.system(.caption2, design: .monospaced))
                                    .id(index)
                            }
                        }
                        .padding(8)
                    }
                    .frame(height: 180)
                    .background(Color(.systemGray6))
                    .onChange(of: logs.count) {
                        if let last = logs.indices.last {
                            proxy.scrollTo(last, anchor: .bottom)
                        }
                    }
                }

                Button("Clear Logs") {
                    logs.removeAll()
                }
                .font(.caption)
                .padding(.bottom, 4)
            }
        }
        .onChange(of: incomingURL) {
            guard let url = incomingURL else { return }
            let timestamp = DateFormatter.logFormatter.string(from: Date())
            logs.append("[\(timestamp)] App opened via URL scheme: \(url.absoluteString)")

            // Pass the return URL to WebView so it can resume the app switch
            // in the existing page — do NOT reload
            returnURL = url
            incomingURL = nil
        }
        .onOpenURL { url in
            incomingURL = url
        }
    }

    private func loadURL() {
        var text = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.contains("://") {
            text = "https://\(text)"
            urlText = text
        }
        currentURL = URL(string: text)
    }
}
