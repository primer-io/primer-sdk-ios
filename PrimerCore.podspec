Pod::Spec.new do |s|
    s.name         = "PrimerCore"
    s.version      = "1.0.0"
    s.summary      = "Core objects + utilities for Primer SDK"
    s.description  = <<-DESC
      This library contains core objects + utilities used by PrimerSDK.
    DESC
    s.homepage     = "https://www.primer.io"
    s.license      = { :type => "MIT", :file => "LICENSE" }
    s.author       = { "Primer" => "dx@primer.io" }
    s.source       = { :git => "https://github.com/primer-io/primer-sdk-ios.git", :tag => "PrimerCore/#{s.version}" }

    s.swift_version = '5'
    s.ios.deployment_target = '13.0'

    s.source_files = "Packages/PrimerCore/Sources/PrimerCore/**/*"
    s.ios.frameworks  = "Foundation", "UIKit"
    
    s.dependency "PrimerFoundation"
    s.dependency "Primer3DS"
end
