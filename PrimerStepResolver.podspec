Pod::Spec.new do |s|
    s.name         = "PrimerStepResolver"
    s.version      = "2.46.1"
    s.summary      = "Step resolution engine for Primer iOS SDK"
    s.description  = "Step resolution and navigation logic for Primer Backend Driven Checkout."
    s.homepage     = "https://www.primer.io"
    s.license      = { :type => "MIT", :file => "LICENSE" }
    s.author       = { "Primer" => "dx@primer.io" }
    s.source       = { :git => "https://github.com/primer-io/primer-sdk-ios.git", :tag => "#{s.version}" }

    s.swift_version = '5'
    s.ios.deployment_target = '13.0'

    s.ios.source_files = "Packages/PrimerStepResolver/Sources/**/*.{swift}"
    s.ios.frameworks   = "Foundation"

    s.dependency "PrimerFoundation", "~> #{s.version}"
end
