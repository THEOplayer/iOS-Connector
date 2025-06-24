#
#  Be sure to run `pod spec lint AdscriptApiClient.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

# info_plist_path = "./Frameworks/AdscriptApiClient.xcframework/ios-arm64/AdscriptApiClient.framework/Info.plist"
# info_cflist = CFPropertyList::List.new(:file => info_plist_path)
# info_plist  = CFPropertyList.native_types(info_cflist.value)
# adscriptApiClientVersion  = info_plist["CFBundleShortVersionString"]

# puts "Detected  AdscriptApiClient XCFramework"
# puts "  - version #{theoadscriptApiClientVersionSdkVersion}"

adscriptApiClientVersion = "1.0.4"

Pod::Spec.new do |spec|

  spec.name         = "AdscriptApiClient"
  spec.version      = adscriptApiClientVersion
  spec.summary      = "The Adscript Api Client for iOS"

  spec.description  = "T"

  spec.homepage     = "https://theoplayer.com"
  spec.license      = "MIT"

  spec.author             = { "Wonne Joosen" => "wonne.joosen@dolby.com" }

  spec.source       = { :git => "https://www.theoplayer.com/.git", :tag => "#{spec.version}" }

  spec.source_files  = "Classes", "Classes/**/*.{h,m}"

  spec.ios.vendored_frameworks = "AdScriptNoTrackingApiClient.xcframework"

end
