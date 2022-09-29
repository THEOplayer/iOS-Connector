#
# Be sure to run `pod lib lint THEOplayerConvivaConnector.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'THEOplayerConvivaConnector'
  s.version          = '0.1.0'
  s.summary          = 'Tools to report THEOplayer events to Conviva'

  s.description      = 'This pod gives you access to classes that let you report playback events from a THEOplayer instance to Conviva'

  s.homepage         = 'https://github.com/Dev1an/THEOplayerConvivaConnector'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'THEO technologies' => 'damiaan.dufaux@theoplayer.com' }
  s.source           = { :git => 'https://github.com/Dev1an/THEOplayerConvivaConnector.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'

  s.source_files = 'Sources/ConvivaConnector/**/*'
      
  s.dependency 'ConvivaSDK', '4.0.31'
  s.dependency 'THEOplayerSDK-basic', '~> 4.0'
end
