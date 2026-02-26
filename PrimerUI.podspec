Pod::Spec.new do |s|
    s.name         = "PrimerUI"
    s.version      = "1.0.0"
    s.summary      = "UI and UI extensions for Primer SDK"
    s.description  = <<-DESC
      This library contains UI and UI extensions used by PrimerSDK.
    DESC
    s.homepage     = "https://www.primer.io"
    s.license      = { :type => "MIT", :file => "LICENSE" }
    s.author       = { "Primer" => "mobile@primer.io" }
    s.source       = { :git => "https://github.com/primer-io/primer-sdk-ios.git", :tag => "PrimerUI/#{s.version}" }

    s.swift_version = '5'
    s.ios.deployment_target = '13.0'

    s.source_files = "Packages/PrimerUI/Sources/PrimerUI/**/*"
    s.ios.frameworks  = "Foundation", "UIKit"
    
end
