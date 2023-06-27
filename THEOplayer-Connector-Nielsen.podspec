require_relative './THEOplayer-Connector-Version'

Pod::Spec.new do |s|
  s.name             = 'THEOplayer-Connector-Nielsen'
  s.module_name      = 'THEOplayerConnectorNielsen'
  s.version          = theoplayer_connector_version
  s.summary          = 'Integration between the THEOplayerSDK and NielsenAppSDK'

  s.description      = 'This pod gives you access to classes that let you report playback events from a THEOplayer instance to Nielsen'

  s.homepage         = 'https://github.com/THEOplayer/iOS-Connector'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = "THEO technologies"
  s.source           = { :git => 'https://github.com/THEOplayer/iOS-Connector.git', :tag => s.version.to_s }

  s.platforms    = { :ios => "12.0", :tvos => "12.0" }

  s.source_files = 'Code/Nielsen/Source/**/*'
      
  s.static_framework = true
  s.swift_versions = ['5.3', '5.4', '5.5', '5.6', '5.7']
  s.ios.dependency 'NielsenAppSDK', '9.0.0.0'
  s.tvos.dependency 'NielsenTVOSAppSDK', '9.0.0.0'
  s.dependency 'THEOplayerSDK-core', "~> 5.5", ">= 5.5.1"
  s.dependency 'THEOplayer-Connector-Utilities', "~> " + theoplayer_connector_major_minor_version, ">= " + theoplayer_connector_version
end
