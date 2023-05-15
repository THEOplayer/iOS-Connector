#
#  Be sure to run `pod spec lint THEOplayerSDK.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

info_plist_path = "./Frameworks/THEOplayerSDK.xcframework/ios-arm64/THEOplayerSDK.framework/Info.plist"
info_cflist = CFPropertyList::List.new(:file => info_plist_path)
info_plist  = CFPropertyList.native_types(info_cflist.value)
theoSdkVersion  = info_plist["CFBundleShortVersionString"]
theoSdkFeatures = info_plist["THEOplayer build information"]["Features"].split(",")

puts "Detected custom THEOplayerSDK XCFramework"
puts "  - version #{theoSdkVersion}"
puts "  - features #{theoSdkFeatures}"

Pod::Spec.new do |spec|

  spec.name         = "THEOplayerSDK-core"
  spec.version      = theoSdkVersion
  spec.summary      = "A custom build of THEOplayerSDK"

  spec.description  = "T"

  spec.homepage     = "https://theoplayer.com"
  spec.license      = "MIT"

  spec.author             = { "Damiaan Dufaux" => "damiaan.dufaux@theoplayer.com" }

  spec.source       = { :git => "https://www.theoplayer.com/.git", :tag => "#{spec.version}" }

  spec.source_files  = "Classes", "Classes/**/*.{h,m}"

  spec.ios.vendored_frameworks = "Frameworks/THEOplayerSDK.xcframework"

end
