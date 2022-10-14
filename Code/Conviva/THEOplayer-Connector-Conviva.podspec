Pod::Spec.new do |s|
  s.name             = 'THEOplayer-Connector-Conviva'
  s.module_name      = 'THEOplayerConnectorConviva'
  s.version          = '4.1.1'
  s.summary          = 'Integration between the THEOplayerSDK and ConvivaSDK'

  s.description      = 'This pod gives you access to classes that let you report playback events from a THEOplayer instance to Conviva'

  s.homepage         = 'https://github.com/THEOplayer/ios-connector'
  s.license          = { :type => 'MIT', :file => '../../LICENSE' }
  s.author           = "THEO technologies"
  s.source           = { :git => 'https://github.com/THEOplayer/ios-connector.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'

  s.source_files = 'Source/**/*'
      
  s.dependency 'ConvivaSDK', '4.0.31'
  s.dependency 'THEOplayerSDK-basic', '4.1.1'
end
