Pod::Spec.new do |s|
  s.name             = 'THEOplayer-Connector-Conviva'
  s.module_name      = 'THEOplayerConnectorConviva'
  s.version          = '4.1.1'
  s.summary          = 'Integration between the THEOplayerSDK and ConvivaSDK'

  s.description      = 'This pod gives you access to classes that let you report playback events from a THEOplayer instance to Conviva'

  s.homepage         = 'https://github.com/THEOplayer/iOS-Connector'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = "THEO technologies"
  s.source           = { :git => 'https://github.com/THEOplayer/iOS-Connector.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'

  s.source_files = 'Code/Conviva/Source/**/*'
      
  s.static_framework = true
  s.swift_versions = ['5.3', '5.4', '5.5', '5.6', '5.7']
  s.dependency 'ConvivaSDK', '~> 4.0.30'
  s.dependency 'THEOplayerSDK-basic', '4.1.1'
end
