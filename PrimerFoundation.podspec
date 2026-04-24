Pod::Spec.new do |s|
    s.name         = "PrimerFoundation"
    s.version      = "2.47.0"
    s.summary      = "Foundation utilities for Primer iOS SDK"
    s.description  = "Foundation utilities, models, and extensions for the Primer iOS SDK."
    s.homepage     = "https://www.primer.io"
    s.license      = { :type => "MIT", :file => "LICENSE" }
    s.author       = { "Primer" => "sdk@primer.io" }
    s.source       = { :git => "https://github.com/primer-io/primer-sdk-ios.git", :tag => "#{s.version}" }

    s.swift_version = '5'
    s.ios.deployment_target = '13.0'

    s.ios.source_files = "Packages/PrimerFoundation/Sources/**/*.{swift}"
    s.ios.frameworks   = "Foundation"
end
