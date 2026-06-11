Pod::Spec.new do |s|
    s.name         = "PrimerNetworking"
    s.version      = "3.0.0-b0"
    s.summary      = "Networking objects + utilities for Primer SDK"
    s.description  = "Networking objects and utilities used by PrimerSDK."
    s.homepage     = "https://www.primer.io"
    s.license      = { :type => "MIT", :file => "LICENSE" }
    s.author       = { "Primer" => "sdk@primer.io" }
    s.source       = { :git => "https://github.com/primer-io/primer-sdk-ios.git", :tag => "#{s.version}" }

    s.swift_version = '5'
    s.ios.deployment_target = '13.0'

    s.ios.source_files = "Modules/PrimerNetworking/Sources/**/*.{swift}"
    s.ios.frameworks   = "Foundation", "UIKit"

    s.dependency "PrimerFoundation", "= #{s.version}"
end
