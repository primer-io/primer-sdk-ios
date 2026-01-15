Pod::Spec.new do |s|
    s.name         = "PrimerFoundation"
    s.version      = "1.0.0"
    s.summary      = "Foundation utilities for Primer SDK"
    s.description  = <<-DESC
    This library contains foundational utilities and extensions used by PrimerSDK. It includes extensions for primitive types and other common utilities.
    DESC
    s.homepage     = "https://www.primer.io"
    s.license      = { :type => "MIT", :file => "LICENSE" }
    s.author       = { "Primer" => "dx@primer.io" }
    s.source       = { :git => "https://github.com/primer-io/primer-sdk-ios.git", :tag => "PrimerFoundation/#{s.version}" }

    s.swift_version = '5'
    s.ios.deployment_target = '13.0'

    s.source_files = "Packages/PrimerFoundation/Sources/PrimerFoundation/**/*"
    s.ios.frameworks  = "Foundation", "UIKit"
end
