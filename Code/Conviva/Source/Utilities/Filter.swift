//
//  AdEventFilter.swift
//  
//
//  Created by Damiaan Dufaux on 09/09/2022.
//

import Dispatch

class Filter {
    typealias Function<Argument> = (Argument)->Void
    
    let queue = DispatchQueue(label: "Filter")
    var letThrough = false
            
    func sendConditionally<Argument>(argument: Argument, function: Function<Argument>) {
        queue.sync {
            if self.letThrough {
                function(argument)
            }
        }
    }
    
    func conditionalSender<Argument>(_ function: @escaping Function<Argument>) -> Function<Argument> {
        { self.sendConditionally(argument: $0, function: function) }
    }
    
    func togglingSender<Argument>(_ function: @escaping Function<Argument>, setLetTroughTo newValue: Bool) -> Function<Argument> {
        { argument in
            self.queue.sync {
                self.letThrough = newValue
                function(argument)
            }
        }
    }
}
