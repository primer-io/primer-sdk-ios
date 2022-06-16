Pod::Spec.new do |s|
    s.name         = "PrimerSDK"
    s.version      = "1.36.1"
    s.summary      = "Official iOS SDK for Primer"
    s.description  = <<-DESC
    This library contains the official iOS SDK for Primer. Install this Cocoapod to seemlessly integrate the Primer Checkout & API platform in your app.
    DESC
    s.homepage     = "https://www.primer.io"
    s.license      = { :type => "MIT", :file => "LICENSE" }
    s.author       = { "Primer" => "dx@primer.io" }
    s.source       = { :git => "https://github.com/primer-io/primer-sdk-ios.git", :tag => "#{s.version}" }
    
    s.swift_version = "4.2"
    s.ios.deployment_target = '10.0'
    
    s.default_subspec = 'Core'
    s.ios.frameworks  = 'Foundation', 'UIKit'
    
    s.subspec 'Core' do |ss|
        ss.ios.source_files = 'Sources/PrimerSDK/Classes/**/*.{h,m,swift}'
        ss.ios.resource_bundles = {
            'PrimerResources' => [
                'Sources/PrimerSDK/Resources/*.xcassets',
                'Sources/PrimerSDK/Resources/Localizable/*',
                'Sources/PrimerSDK/Resources/Storyboards/*.{storyboard}',
                'Sources/PrimerSDK/Resources/Nibs/*',
                'Sources/PrimerSDK/Resources/JSONs/*'
            ]
        }
        ss.ios.pod_target_xcconfig = {
            "FRAMEWORK_SEARCH_PATHS" => [
                "${PODS_CONFIGURATION_BUILD_DIR}/Primer3DS",
            ]
        }
    end
end
