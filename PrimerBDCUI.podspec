Pod::Spec.new do |s|
    s.name         = "PrimerBDCUI"
    s.version      = "3.0.0-beta.7"
    s.summary      = "Backend Driven Checkout server-driven UI for Primer iOS SDK"
    s.description  = "Server-driven UI rendering for Primer Backend Driven Checkout."
    s.homepage     = "https://www.primer.io"
    s.license      = { :type => "MIT", :file => "LICENSE" }
    s.author       = { "Primer" => "sdk@primer.io" }
    s.source       = { :git => "https://github.com/primer-io/primer-sdk-ios.git", :tag => "#{s.version}" }

    s.swift_version = '5'
    s.ios.deployment_target = '15.0'

    s.ios.source_files = "Modules/PrimerBDCUI/Sources/**/*.{swift}"
    s.ios.frameworks   = "Foundation", "SwiftUI", "UIKit"

    s.dependency "PrimerFoundation", "= #{s.version}"
    s.dependency "PrimerStepResolver", "= #{s.version}"
end
