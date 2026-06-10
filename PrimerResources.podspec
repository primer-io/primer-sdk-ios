Pod::Spec.new do |s|
    s.name         = "PrimerResources"
    s.version      = "2.49.0"
    s.summary      = "Resources for Primer SDK"
    s.description  = "Contains resources (images, localisations, etc) used by PrimerSDK."
    s.homepage     = "https://www.primer.io"
    s.license      = { :type => "MIT", :file => "LICENSE" }
    s.author       = { "Primer" => "sdk@primer.io" }
    s.source       = { :git => "https://github.com/primer-io/primer-sdk-ios.git", :tag => "#{s.version}" }

    s.swift_version = '5'
    s.ios.deployment_target = '13.0'

    s.source_files = "Modules/PrimerResources/Sources/PrimerResources/**/*.swift"
    s.ios.resource_bundles = {
        "PrimerResources" => [
            "Modules/PrimerResources/Sources/PrimerResources/Resources/*.xcassets",
            "Modules/PrimerResources/Sources/PrimerResources/Resources/Localizable/**/*.strings",
            "Modules/PrimerResources/Sources/PrimerResources/Resources/Localizable/**/*.stringsdict",
            "Modules/PrimerResources/Sources/PrimerResources/Resources/Nibs/*",
            "Modules/PrimerResources/Sources/PrimerResources/Resources/JSONs/**/*.json"
        ]
    }
end
