require_relative './THEOplayer-Connector-Version'

Pod::Spec.new do |s|
  s.name             = 'THEOplayer-Connector-Conviva'
  s.module_name      = 'THEOplayerConnectorConviva'
  s.version          = theoplayer_connector_version
  s.summary          = 'Integration between the THEOplayerSDK and ConvivaSDK'

  s.description      = 'This pod gives you access to classes that let you report playback events from a THEOplayer instance to Conviva'

  s.homepage         = 'https://github.com/THEOplayer/iOS-Connector'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = "THEO technologies"
  s.source           = { :git => 'https://github.com/THEOplayer/iOS-Connector.git', :tag => s.version.to_s }

  s.platforms    = { :ios => "13.0", :tvos => "13.0" }

  s.source_files = 'Code/Conviva/Source/**/*'
      
  s.static_framework = true
  s.swift_versions = ['5.3', '5.4', '5.5', '5.6', '5.7']
  
  # --- Subspec: Base (default) ---
  s.subspec 'Base' do |base|
    base.source_files = 'Code/Conviva/Source/Base/**/*'
    base.dependency 'ConvivaSDK', '4.0.51'
    base.dependency 'THEOplayerSDK-core', "~> 10.0"
    base.dependency 'THEOplayer-Connector-Utilities', "~> " + theoplayer_connector_major_minor_version, ">= " + theoplayer_connector_version
  end
  
  # --- Subspec: THEOlive ---
  s.subspec 'THEOlive' do |deps|
    deps.source_files = 'Code/Conviva/Source/THEOlive/**/*'
    deps.dependency 'THEOplayer-Integration-THEOlive', "~> 10.0"
  end
  
  # Default
  s.default_subspecs = ['Base', 'THEOlive']
end
