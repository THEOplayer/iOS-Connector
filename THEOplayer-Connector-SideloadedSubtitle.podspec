require_relative './THEOplayer-Connector-Version'

Pod::Spec.new do |s|
  s.name             = 'THEOplayer-Connector-SideloadedSubtitle'
  s.module_name      = 'THEOplayerConnectorSideloadedSubtitle'
  s.version          = theoplayer_connector_version
  s.summary          = 'Sideloaded subtitle support for THEOplayer'

  s.description      = 'THEOplayer-Connector-SideloadedSubtitle brings sideloaded subtitle support to THEOplayer across all supported Apple platforms in all supported media playback scenarios'

  s.homepage         = 'https://github.com/THEOplayer/iOS-Connector'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = "THEO technologies"
  s.source           = { :git => 'https://github.com/THEOplayer/iOS-Connector.git', :tag => s.version.to_s }

  s.platforms    = { :ios => "13.0", :tvos => "13.0" }

  s.source_files = 'Code/Sideloaded-TextTracks/Sources/THEOplayerConnectorSideloadedSubtitle/**/*'
      
  s.static_framework = true
  s.swift_versions = ['5.3', '5.4', '5.5', '5.6', '5.7']
  s.dependency 'THEOplayerSDK-core', "~> 7.10"
  s.dependency 'SwiftSubtitles', '0.9.1'
  s.dependency 'Swifter', '1.5.0'
end
