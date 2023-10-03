require_relative './THEOplayer-Connector-Version'

Pod::Spec.new do |s|
  s.name             = 'THEOplayer-Connector-Utilities'
  s.module_name      = 'THEOplayerConnectorUtilities'
  s.version          = theoplayer_connector_version
  s.summary          = 'Helpers for attaching and detaching event listeners on THEOplayers'

  s.description      = 'This pod gives you access to helpers for attaching and detaching event listeners on THEOplayers'

  s.homepage         = 'https://github.com/THEOplayer/iOS-Connector'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = "THEO technologies"
  s.source           = { :git => 'https://github.com/THEOplayer/iOS-Connector.git', :tag => s.version.to_s }

  s.platforms    = { :ios => "12.0", :tvos => "12.0" }

  s.source_files = 'Code/Utilities/Source/**/*'
      
  s.static_framework = true
  s.swift_versions = ['5.3', '5.4', '5.5', '5.6', '5.7']
  s.dependency 'ConvivaSDK', '~> 4.0.30'
  s.dependency 'THEOplayerSDK-core', "~> 6.1"
end
