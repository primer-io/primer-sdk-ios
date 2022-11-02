//
//  PMF.swift
//  ExampleAppTests
//
//  Created by Evangelos on 1/11/22.
//  Copyright © 2022 Primer API Ltd. All rights reserved.
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

class PMFTests: XCTestCase {
    
    let multibancoPMFResponse = """
{
    "events": [{
            "type": "ON_START",
            "action": {
                "type": "NAVIGATE",
                "screenId": "start_screen"
            }
        },
        {
            "type": "ON_ADDITIONAL_DATA_RECEIVED",
            "action": {
                "type": "NAVIGATE",
                "screenId": "voucher_screen"
            }
        },
        {
            "type": "ON_ERROR",
            "action": {
                "type": "NAVIGATE",
                "screenId": "error_screen"
            }
        }
    ],
    "screens": [{
            "id": "start_screen",
            "isBackButtonEnabled": true,
            "orientation": "VERTICAL",
            "components": [{
                    "type": "TEXT",
                    "text": "Proceed to pay etc",
                    "style": {
                        "textStyle": "TITLE",
                        "margin": {
                            "top": 50
                        }
                    }
                },
                {
                    "type": "BUTTON",
                    "text": "Submit",
                    "buttonType": "PAY",
                    "onClickAction": {
                        "type": "START_FLOW"
                    }
                }
            ]
        },
        {
            "id": "voucher_screen",
            "isBackButtonEnabled": false,
            "orientation": "VERTICAL",
            "components": [{
                    "type": "TEXT",
                    "text": "Here is your voucher",
                    "style": {
                        "textStyle": "TITLE",
                        "margin": {
                            "top": 50
                        }
                    }
                },
                {
                    "type": "TEXT",
                    "text": "{entity}",
                    "style": {
                        "textStyle": "SUBTITLE",
                        "margin": {
                            "top": 50
                        }
                    }
                },
                {
                    "type": "BUTTON",
                    "text": "Done",
                    "buttonType": "DEFAULT",
                    "onClickAction": {
                        "type": "DISMISS"
                    }
                }
            ]
        }
    ]
}
"""
    
    func test_multibancoPMF_parsing() throws {
        do {
            let multibancoPMF = try JSONDecoder().decode(PMF.self, from: self.multibancoPMFResponse.data(using: .utf8)!)
            
            XCTAssert(multibancoPMF.events.count == 3, "Multibanco response should contain 3 events.")
            
            XCTAssert(multibancoPMF.screens.count == 2, "Multibanco response should contain 2 screens.")
            
            XCTAssert(multibancoPMF.events.filter({ $0.`type` == .onStart }).count == 1, "Multibanco PMF's events should contain 1 'onStart' event.")
            
            XCTAssert(multibancoPMF.events.filter({ $0.`type` == .onAdditionalDataReceived }).count == 1, "Multibanco PMF's events should contain 1 'onAdditionalDataReceived' event.")
            
            XCTAssert(multibancoPMF.events.filter({ $0.`type` == .onError }).count == 1, "Multibanco PMF's events should contain 1 'onError' event.")
            
            let onStartEvent = multibancoPMF.events.first(where: { $0.type == .onStart })!
            
            XCTAssert(onStartEvent.action.type == .navigate, "Multibanco's 'onStart' event should have action 'navigate'.")
            
            XCTAssert(onStartEvent.action.screenId == "start_screen", "Multibanco's 'onStart' event should have screen id 'start_screen'.")
            
            let onAdditionalDataReceivedEvent = multibancoPMF.events.first(where: { $0.type == .onAdditionalDataReceived })!
            
            XCTAssert(onAdditionalDataReceivedEvent.action.type == .navigate, "Multibanco's 'onAdditionalDataReceivedEvent' event should have action 'navigate'.")
            
            XCTAssert(onAdditionalDataReceivedEvent.action.screenId == "voucher_screen", "Multibanco's 'onAdditionalDataReceivedEvent' event should have screen id 'voucher_screen'.")
            
            let onErrorEvent = multibancoPMF.events.first(where: { $0.type == .onError })!
            
            XCTAssert(onErrorEvent.action.type == .navigate, "Multibanco's 'onErrorEvent' event should have action 'navigate'.")
            
            XCTAssert(onErrorEvent.action.screenId == "error_screen", "Multibanco's 'onErrorEvent' event should have screen id 'error_screen'.")
            
            XCTAssert(multibancoPMF.screens.first(where: { $0.id == "start_screen" }) != nil, "Multibanco PMF's screens should contain 1 'start_screen' screen.")
            
            let startScreen = multibancoPMF.screens.first(where: { $0.id == "start_screen" })!
            
            XCTAssert(startScreen.isBackButtonEnabled == true, "Multibanco's start screen should have its back button enabled.")
            
            XCTAssert(startScreen.orientation == .vertical, "Multibanco's start screen should have vertical orientation.")
            
            XCTAssert(startScreen.components.count == 2, "Multibanco's start screen should have 2 components.")
            
            let startScreenTextComponent = startScreen.components.first(where: {
                switch $0 {
                case .text:
                    return true
                default:
                    return false
                }
            })
                
            XCTAssert(startScreenTextComponent != nil, "Multibanco's start screen should have 1 text component.")
                        
            let startScreenButtonComponent = startScreen.components.first(where: {
                switch $0 {
                case .button:
                    return true
                default:
                    return false
                }
            })
                
            XCTAssert(startScreenButtonComponent != nil, "Multibanco's start screen should have 1 button component.")
            
            XCTAssert(multibancoPMF.screens.first(where: { $0.id == "voucher_screen" }) != nil, "Multibanco PMF's screens should contain 1 'voucher_screen' screen.")
            
            let voucherScreen = multibancoPMF.screens.first(where: { $0.id == "voucher_screen" })!
            
            let voucherScreenTextComponents = voucherScreen.components.filter({
                switch $0 {
                case .text:
                    return true
                default:
                    return false
                }
            })
                
            XCTAssert(voucherScreenTextComponents.count == 2, "Multibanco's start screen should have 2 text components.")
            
            let voucherScreenButtonComponents = voucherScreen.components.filter({
                switch $0 {
                case .button:
                    return true
                default:
                    return false
                }
            })
                
            XCTAssert(voucherScreenButtonComponents.count == 1, "Multibanco's start screen should have 1 button component.")
            
            XCTAssert(true)
            
        } catch {
            XCTFail("\(error)")
        }
    }
}


#endif
