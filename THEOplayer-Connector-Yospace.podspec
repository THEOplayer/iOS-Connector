require_relative './THEOplayer-Connector-Version'

Pod::Spec.new do |s|
  s.name             = 'THEOplayer-Connector-Yospace'
  s.module_name      = 'THEOplayerConnectorYospace'
  s.version          = theoplayer_connector_version
  s.summary          = 'Integration between the THEOplayerSDK and Yospace'

  s.description      = 'This pod gives you access to classes that help integrate Yospace with THEOplayer to allow playback of server-side ad inserted streams.'

  s.homepage         = 'https://github.com/THEOplayer/iOS-Connector'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = "THEO technologies"
  s.source           = { :git => 'https://github.com/THEOplayer/iOS-Connector.git', :tag => s.version.to_s }

  s.platforms    = { :ios => "12.0", :tvos => "12.0" }

  s.source_files = 'Code/Yospace/Source/**/*'

  s.static_framework = true
  s.swift_versions = ['5.3', '5.4', '5.5', '5.6', '5.7']
  s.dependency 'THEOplayerSDK-core', "~> 7.8"
end
