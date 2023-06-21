//
//  ConvivaConnectorStorage.swift
//  
//
//  Created on 20/06/2023.
//

public class ConvivaConnectorStorage {
    private var storedValues: [String:Any] = [:]
    
    public func storeKeyValuePair(key: String, value: Any) {
        storedValues.updateValue(value, forKey: key)
    }
    
    public func storeKeyValueMap(_ map: [String:Any]) {
        for (key, value) in map {
            self.storeKeyValuePair(key: key, value: value)
        }
    }
    
    public func valueForKey(_ key: String) -> Any? {
        return storedValues[key]
    }
}
