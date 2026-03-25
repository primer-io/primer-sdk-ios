Pod::Spec.new do |s|
    s.name         = "PrimerStepResolver"
    s.version      = "1.0.0"
    s.summary      = "Step resolution engine for Primer iOS SDK"
    s.description  = "Step resolution and navigation logic for Primer Backend Driven Checkout."
    s.homepage     = "https://www.primer.io"
    s.license      = { :type => "MIT", :file => "LICENSE" }
    s.author       = { "Primer" => "sdk@primer.io" }
    s.source       = { :git => "https://github.com/primer-io/primer-sdk-ios.git", :tag => "PrimerStepResolver-#{s.version}" }

    s.swift_version = '5'
    s.ios.deployment_target = '13.0'

    s.ios.source_files = "Packages/PrimerStepResolver/Sources/**/*.{swift}"
    s.ios.frameworks   = "Foundation"

    s.dependency "PrimerFoundation", "~> 1.1"
end
