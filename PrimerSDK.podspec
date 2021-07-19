
Pod::Spec.new do |spec|
    spec.name         = "PrimerSDK"
    spec.version      = "1.8.4"
    spec.summary      = "Official iOS SDK for Primer"
    spec.description  = <<-DESC
    This library contains the official iOS SDK for Primer. Install this Cocoapod to seemlessly integrate the Primer Checkout & API platform in your app.
    DESC
    spec.homepage     = "https://www.primer.io"
    spec.license      = { :type => "MIT", :file => "LICENSE" }
    spec.author       = { "Primer" => "carl@primer.io" }
    spec.source       = { :git => "https://github.com/primer-io/primer-sdk-ios.git", :tag => "#{spec.version}" }
    
    spec.swift_version = "5.3"
    spec.ios.deployment_target = '10.0'
    
    spec.source_files = 'Sources/PrimerSDK/Classes/**/*.{h,m,swift}'
#    spec.resources = [
##        'Sources/PrimerSDK/Resources/*.xcassets',
##        'Sources/PrimerSDK/Resources/Localizable/*'
#    ]
    spec.resource_bundles = {
        'PrimerResources' => [
            'Sources/PrimerSDK/Resources/*.xcassets',
            'Sources/PrimerSDK/Resources/Localizable/*'
        ]
    }
    
    spec.test_spec 'PrimerSDKTests' do |test_spec|
        test_spec.source_files = 'Tests/**/*.{h,m,swift}'
    end
    
end
