Pod::Spec.new do |s|
    s.name         = "PrimerBDCCore"
    s.version      = "1.0.1"
    s.summary      = "Backend Driven Checkout core orchestration for Primer iOS SDK"
    s.description  = "Core orchestration layer for Primer Backend Driven Checkout."
    s.homepage     = "https://www.primer.io"
    s.license      = { :type => "MIT", :file => "LICENSE" }
    s.author       = { "Primer" => "sdk@primer.io" }
    s.source       = { :git => "https://github.com/primer-io/primer-sdk-ios.git", :tag => "PrimerBDCCore-#{s.version}" }

    s.swift_version = '5'
    s.ios.deployment_target = '13.0'

    s.ios.source_files = "Packages/PrimerBDCCore/Sources/**/*.{swift}"
    s.ios.frameworks   = "Foundation", "SafariServices", "UIKit"

    s.dependency "PrimerBDCEngine", "~> 1.0"
    s.dependency "PrimerFoundation", "~> 1.0"
    s.dependency "PrimerStepResolver", "~> 1.0"
end
