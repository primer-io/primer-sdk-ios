
Pod::Spec.new do |s|
    s.name         = "PrimerSDK"
    s.version      = "1.8.5"
    s.summary      = "Official iOS SDK for Primer"
    s.description  = <<-DESC
    This library contains the official iOS SDK for Primer. Install this Cocoapod to seemlessly integrate the Primer Checkout & API platform in your app.
    DESC
    s.homepage     = "https://www.primer.io"
    s.license      = { :type => "MIT", :file => "LICENSE" }
    s.author       = { "Primer" => "dx@primer.io" }
    s.source       = { :git => "https://github.com/primer-io/primer-sdk-ios.git", :tag => "#{s.version}" }
    
    s.swift_version = "5.3"
    s.ios.deployment_target = '10.0'
    
    s.default_subspec = 'Core'
    
    s.subspec 'Core' do |ss|
        ss.source_files = 'Sources/PrimerSDK/Classes/**/*.{h,m,swift}'
    #    s.resources = [
    ##        'Sources/PrimerSDK/Resources/*.xcassets',
    ##        'Sources/PrimerSDK/Resources/Localizable/*'
    #    ]
        ss.resource_bundles = {
            'PrimerResources' => [
                'Sources/PrimerSDK/Resources/*.xcassets',
                'Sources/PrimerSDK/Resources/Localizable/*',
            ]
        }
    end
    
    s.subspec '3DS' do |ss|
      ss.dependency 'Primer3DS'
  #    ss.source_files = 'Primer3DS/Classes/**/*'
  #    ss.vendored_frameworks = 'Primer3DS/Frameworks/ThreeDS_SDK.xcframework'
    end
    
    s.test_spec 'PrimerSDKTests' do |test_spec|
        test_spec.source_files = 'Tests/**/*.{h,m,swift}'
    end
    
end
