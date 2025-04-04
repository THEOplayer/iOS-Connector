//
//  AdEventFilter.swift
//  
//
//  Created by Damiaan Dufaux on 09/09/2022.
//

import Dispatch

public class Filter {
    public typealias Function<Argument> = (Argument)->Void
    
    let queue = DispatchQueue.main
    var letThrough = false
    
    public init() {}
            
    public func sendConditionally<Argument>(argument: Argument,  function: @escaping Function<Argument>) {
        queue.async {
            if self.letThrough {
                function(argument)
            }
        }
    }
    
    public func conditionalSender<Argument>(_ function: @escaping Function<Argument>) -> Function<Argument> {
        { self.sendConditionally(argument: $0, function: function) }
    }
    
    public func togglingSender<Argument>(_ function: @escaping Function<Argument>, setLetThroughTo newValue: Bool) -> Function<Argument> {
        { argument in
            self.queue.async {
                self.letThrough = newValue
                function(argument)
            }
        }
    }
}
