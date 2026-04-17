Pod::Spec.new do |s|
    s.name         = "PrimerBDCEngine"
    s.version      = "1.0.1"
    s.summary      = "Backend Driven Checkout engine for Primer iOS SDK"
    s.description  = "JS-based state processing engine for Primer Backend Driven Checkout."
    s.homepage     = "https://www.primer.io"
    s.license      = { :type => "MIT", :file => "LICENSE" }
    s.author       = { "Primer" => "sdk@primer.io" }
    s.source       = { :git => "https://github.com/primer-io/primer-sdk-ios.git", :tag => "PrimerBDCEngine-#{s.version}" }

    s.swift_version = '5'
    s.ios.deployment_target = '13.0'

    s.ios.source_files = "Packages/PrimerBDCEngine/Sources/**/*.{swift}"
    s.ios.frameworks   = "JavaScriptCore", "CryptoKit"

    s.dependency "PrimerFoundation", "~> 1.0"
    s.dependency "PrimerStepResolver", "~> 1.0"
end
