//
//  ConvivaConnectorStorage.swift
//  

public class ConvivaConnectorStorage {
    private var storedValues: [String:Any] = [:]
    
    public func storeKeyValuePair(key: String, value: Any) {
        self.storedValues.updateValue(value, forKey: key)
    }
    
    public func storeKeyValueMap(_ map: [String:Any]) {
        for (key, value) in map {
            self.storeKeyValuePair(key: key, value: value)
        }
    }
    
    public func valueForKey(_ key: String) -> Any? {
        return self.storedValues[key]
    }
    
    func clearValueForKey(_ key: String) {
        self.storedValues.removeValue(forKey: key)
    }
}
