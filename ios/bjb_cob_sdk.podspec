#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint bjb_cob_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'bjb_cob_sdk'
  s.version          = '1.0.0'
  s.summary          = 'BJB Customer Onboarding SDK for Flutter (Universal)'
  s.description      = <<-DESC
Universal Flutter plugin for BJB Customer Onboarding SDK supporting both iOS and Android platforms.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'BJB Team' => 'your.email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*', 'sdkCob/**/*.{h,m,swift}'
  s.dependency 'Flutter'
  s.platform = :ios, '15.5'
  
  # Flutter framework path
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES', 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO',
    'IPHONEOS_DEPLOYMENT_TARGET' => '15.5',
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES',
    'FRAMEWORK_SEARCH_PATHS' => '$(inherited) $(FLUTTER_ROOT)/bin/cache/artifacts/engine/ios*'
  }

  # SDK COB Dependencies
  s.dependency 'DigitalIdentity'
  s.dependency 'Ojo'
  s.dependency 'SSZipArchive'
  s.dependency 'Clickstream', '2.0.42'
  s.dependency 'ReachabilitySwift'
  s.dependency 'SwiftProtobuf'
  
  # # Include assets
  # s.resource_bundles = {
  #   'bjb_cob_sdk_assets' => ['sdkCob/Assets.xcassets/**/*']
  # }

  # Include native SDK framework
  s.vendored_frameworks = 'sdkCob.framework'
  s.resources = 'sdkCob/**/*.{png,jpg,jpeg,gif,pdf,xib,storyboard}'
  s.resource_bundles = {
    'bjb_cob_sdk_assets' => ['sdkCob/Assets.xcassets']
  }
  

  s.swift_version = '5.0'
end