//
//  ConvivaConnectorStorage.swift
//  
//
//  Created on 20/06/2023.
//

public class ConvivaConnectorStorage {
    private var storedValues: [String:Any] = [:]
    
    func storeKeyValuePair(key: String, value: Any) {
        self.storedValues.updateValue(value, forKey: key)
    }
    
    func storeKeyValueMap(_ map: [String:Any]) {
        for (key, value) in map {
            self.storeKeyValuePair(key: key, value: value)
        }
    }
    
    public func valueForKey(_ key: String) -> Any? {
        return self.storedValues[key]
    }
    
    func clear() {
        self.storedValues.removeAll()
    }
}
