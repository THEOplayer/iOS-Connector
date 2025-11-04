//
//  ConvivaStorage.swift
//  

class ConvivaStorage {
    private(set) var metrics: [String:Any] = [:]
    private(set) var metadata: [String:Any] = [:]
    
    // MARK: METADATA
    func storeMetadataEntry(key: String, value: Any) {
        self.metadata.updateValue(value, forKey: key)
    }
    
    func storeMetadata(_ map: [String:Any]) {
        for (key, value) in map {
            self.storeMetadataEntry(key: key, value: value)
        }
    }
    
    func metadataEntryForKey(_ key: String) -> Any? {
        return self.metadata[key]
    }
    
    func hasMetadataEntryForKey(_ key: String) -> Bool {
        return self.metadata[key] != nil
    }
    
    func clearMetadataEntryForKey(_ key: String) {
        self.metadata.removeValue(forKey: key)
    }
    
    func clearAllMetadata() {
        self.metadata = [:]
    }
    
    // MARK: METRICS
    func storeMetric(key: String, value: Any) {
        self.metrics.updateValue(value, forKey: key)
    }
    
    func storeMetrics(_ map: [String:Any]) {
        for (key, value) in map {
            self.storeMetric(key: key, value: value)
        }
    }
    
    func metricForKey(_ key: String) -> Any? {
        return self.metrics[key]
    }
    
    func hasMetricForKey(_ key: String) -> Bool {
        return self.metrics[key] != nil
    }
    
    func clearMetricForKey(_ key: String) {
        self.metrics.removeValue(forKey: key)
    }
    
    func clearAllMetrics() {
        self.metrics = [:]
    }
}
