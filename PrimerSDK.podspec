Pod::Spec.new do |spec|
  spec.name         = "PrimerSDK"
  spec.version      = "1.1.13"
  spec.summary      = "Official iOS SDK for Primer"
  spec.description  = <<-DESC
  This library contains the official iOS SDK for Primer. Install this Cocoapod to seemlessly integrate the Primer Checkout & API platform in your app.
                   DESC
  spec.homepage     = "http://www.primer.io"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Carl Eriksson" => "carl@primer.io" }
  spec.platform     = :ios, "10.0"
  spec.source       = { :git => "https://github.com/primer-io/primer-sdk-ios.git", :tag => "#{spec.version}" }
  spec.source_files  = "PrimerSDK/**/*.{swift}"
  spec.resource_bundles = {
    'PrimerSDK' => ['PrimerSDK/**/*.xcassets']
  }
  spec.swift_version = "4.2"
  spec.framework  = "UIKit"
  spec.dependency 'CardScan'
  spec.dependency 'Mixpanel-swift'
end
