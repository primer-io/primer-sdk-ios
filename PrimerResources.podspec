Pod::Spec.new do |s|
    s.name         = "PrimerResources"
    s.version      = "1.0.0"
    s.summary      = "Resources for Primer SDK"
    s.description  = <<-DESC
      This library contains resources (images, localisations, JSON data and nibs) used by PrimerSDK.
    DESC
    s.homepage     = "https://www.primer.io"
    s.license      = { :type => "MIT", :file => "LICENSE" }
    s.author       = { "Primer" => "mobile@primer.io" }
    s.source       = { :git => "https://github.com/primer-io/primer-sdk-ios.git", :tag => "PrimerResources/#{s.version}" }

    s.swift_version = '5'
    s.ios.deployment_target = '13.0'

    s.source_files = "Packages/PrimerResources/Sources/PrimerResources/**/*.swift"
    s.ios.resource_bundles = {
        "PrimerResources" => [
            "Packages/PrimerResources/Sources/PrimerResources/Resources/*.xcassets",
            "Packages/PrimerResources/Sources/PrimerResources/Resources/Localizable/**/*.strings",
            "Packages/PrimerResources/Sources/PrimerResources/Resources/Localizable/**/*.stringsdict",
            "Packages/PrimerResources/Sources/PrimerResources/Resources/Nibs/*",
            "Packages/PrimerResources/Sources/PrimerResources/Resources/JSONs/**/*.json"
        ]
    }
end
