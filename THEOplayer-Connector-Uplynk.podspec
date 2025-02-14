require_relative './THEOplayer-Connector-Version'

Pod::Spec.new do |s|
  s.name             = 'THEOplayer-Connector-Uplynk'
  s.module_name      = 'THEOplayerConnectorUplynk'
  s.version          = theoplayer_connector_version
  s.summary          = 'Integration between the THEOplayerSDK and Uplynk CMS'

  s.description      = 'This pod gives you access to classes that let you integrate Uplynk CMS into THEOplayer'

  s.homepage         = 'https://github.com/THEOplayer/iOS-Connector'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = "THEO technologies"
  s.source           = { :git => 'https://github.com/THEOplayer/iOS-Connector.git', :tag => s.version.to_s }

  s.platforms    = { :ios => "13.0", :tvos => "13.0" }

  s.source_files = 'Code/Uplynk/Source/**/*'
      
  s.static_framework = true
  s.dependency 'THEOplayerSDK-core', "~> 8"
end
