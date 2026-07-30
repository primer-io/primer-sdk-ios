Pod::Spec.new do |s|
    s.name         = "PrimerUI"
    s.version      = "3.0.0-beta.3"
    s.summary      = "UI and UI extensions for Primer SDK"
    s.description  = "This library contains UI and UI extensions used by PrimerSDK."
    s.homepage     = "https://www.primer.io"
    s.license      = { :type => "MIT", :file => "LICENSE" }
    s.author       = { "Primer" => "sdk@primer.io" }
    s.source       = { :git => "https://github.com/primer-io/primer-sdk-ios.git", :tag => "#{s.version}" }

    s.swift_version = '5'
    s.ios.deployment_target = '13.0'

    s.ios.source_files = "Modules/PrimerUI/Sources/**/*.{swift}"
    s.ios.frameworks   = "Foundation", "UIKit"
end
