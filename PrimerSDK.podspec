Pod::Spec.new do |spec|
    spec.name         = "PrimerSDK"
    spec.version      = "1.2.2"
    spec.summary      = "Official iOS SDK for Primer"
    spec.description  = <<-DESC
    This library contains the official iOS SDK for Primer. Install this Cocoapod to seemlessly integrate the Primer Checkout & API platform in your app.
    DESC
    spec.homepage     = "https://www.primer.io"
    spec.license      = { :type => "MIT", :file => "LICENSE" }
    spec.author       = { "Primer" => "carl@primer.io" }
    spec.source       = { :git => "https://github.com/primer-io/primer-sdk-ios.git", :tag => "#{spec.version}" }
    # spec.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
    
    spec.ios.deployment_target = '10.0'
    
    spec.source_files = 'PrimerSDK/Classes/**/*'
    
    spec.swift_version = "4.2"
    
    spec.resource_bundles = {
        'PrimerSDK' => ['PrimerSDK/Assets/*.xcassets']
    }
    
    # spec.public_header_files = 'Pod/Classes/**/*.h'
    # spec.frameworks = 'UIKit', 'MapKit'
    # spec.dependency 'AFNetworking', '~> 2.3'
    
end
