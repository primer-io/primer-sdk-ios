
Pod::s.new do |s|
    s.name         = "Primer3DS_SDK"
    s.version      = "0.0.2"
    s.summary      = "Official iOS SDK for Primer"
    s.description  = <<-DESC
    This library contains the official iOS SDK for Primer. Install this Cocoapod to seemlessly integrate the Primer Checkout & API platform in your app.
    DESC
    s.homepage     = "https://www.primer.io"
    s.license      = { :type => "MIT", :file => "LICENSE" }
    s.author       = { "Primer" => "dx@primer.io" }
    s.source       = { :git => "primer-sdk-ios-private", :tag => "#{s.version}" }
    
#     s.swift_version = "5.3"
#     s.ios.deployment_target = '10.0'
    
#     s.source_files = 'Sources/PrimerSDK/Classes/**/*.{h,m,swift}'
# #    s.resources = [
# ##        'Sources/PrimerSDK/Resources/*.xcassets',
# ##        'Sources/PrimerSDK/Resources/Localizable/*'
# #    ]
#     s.resource_bundles = {
#         'PrimerResources' => [
#             'Sources/PrimerSDK/Resources/*.xcassets',
#             'Sources/PrimerSDK/Resources/Localizable/*',
#         ]
#     }
#     s.vendored_frameworks = 'Sources/PrimerSDK/Resources/Frameworks/*'

s.default_subspec = 'Core'
    s.ios.frameworks  = 'Foundation', 'UIKit'
    
    s.subspec 'Core' do |ss|
        ss.ios.source_files = 'Sources/PrimerSDK/Classes/**/*.{h,m,swift}'
        ss.ios.resource_bundles = {
            'PrimerResources' => [
                'Sources/PrimerSDK/Resources/*.xcassets',
                'Sources/PrimerSDK/Resources/Localizable/*',
            ]
        }
#        ss.ios.pod_target_xcconfig = {
#            "PRODUCT_BUNDLE_IDENTIFIER" => "org.cocoapods.PrimerSDK",
#            "DEVELOPMENT_TEAM" => "N8UN9TR5DY",
##            'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
#        }
    end
    
    s.subspec '3DS' do |ss|
      ss.ios.dependency 'Primer3DS'
#      ss.ios.pod_target_xcconfig = {
##          "PRODUCT_BUNDLE_IDENTIFIER" => "io.primer.Primer3DS",
##          "DEVELOPMENT_TEAM" => "N8UN9TR5DY",
#            'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
#      }
#      ss.ios.user_target_xcconfig = {
#          "PRODUCT_BUNDLE_IDENTIFIER" => "org.cocoapods.PrimerSDK-App",
#          "DEVELOPMENT_TEAM" => "N8UN9TR5DY",
##            'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
#      }
  #    ss.source_files = 'Primer3DS/Classes/**/*'
  #    ss.vendored_frameworks = 'Primer3DS/Frameworks/ThreeDS_SDK.xcframework'
    end
    
    s.ios.pod_target_xcconfig = {
#          "PRODUCT_BUNDLE_IDENTIFIER" => "io.primer.Primer3DS",
#          "DEVELOPMENT_TEAM" => "N8UN9TR5DY",
        'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
    }
    s.ios.user_target_xcconfig = {
        'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
    }
    
#    s.user_target_xcconfig = {
#        "PRODUCT_BUNDLE_IDENTIFIER" => "org.cocoapods.PrimerSDK-App",
#        "DEVELOPMENT_TEAM" => "N8UN9TR5DY",
##            'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
#    }
    
#    s.test_spec 'PrimerSDKTests' do |test_spec|
#        test_s.source_files = 'Tests/**/*.{h,m,swift}'
#    end
    
end
