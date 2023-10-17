def versionJson
  require "json"
  jsonFile = File.open "./version.json"
  json = JSON.load jsonFile
end

def theoplayer_connector_major_minor_version
  return versionJson["major_minor"]
end

def theoplayer_connector_bug_version
  return versionJson["patch"]
end

def theoplayer_connector_version
  return theoplayer_connector_major_minor_version + '.' + theoplayer_connector_bug_version
end
