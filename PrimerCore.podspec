Pod::Spec.new do |s|
    s.name         = "PrimerCore"
    s.version      = "2.47.0"
    s.summary      = "Core objects + utilities for Primer SDK"
    s.description  = "Core objects and utilities used by PrimerSDK."
    s.homepage     = "https://www.primer.io"
    s.license      = { :type => "MIT", :file => "LICENSE" }
    s.author       = { "Primer" => "sdk@primer.io" }
    s.source       = { :git => "https://github.com/primer-io/primer-sdk-ios.git", :tag => "#{s.version}" }

    s.swift_version = '5'
    s.ios.deployment_target = '13.0'

    s.ios.source_files = "Packages/PrimerCore/Sources/**/*.{swift}"
    s.ios.frameworks   = "Foundation", "UIKit"

    s.dependency "PrimerFoundation", "= #{s.version}"
    s.dependency "Primer3DS"
end
