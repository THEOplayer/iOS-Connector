//
//  URLSessionExtensions.swift
//
//
//  Copyright © 2023 THEOplayer. All rights reserved.
//

import Foundation

extension URLSession {
    func synchronousDataTask(urlrequest: URLRequest) -> (Data?, Error?) {
        var data: Data?
        var error: Error?

        let semaphore = DispatchSemaphore(value: 0)
        let task = self.dataTask(with: urlrequest) {
            data = $0
            error = $2
            semaphore.signal()
        }
        task.resume()

        _ = semaphore.wait(timeout: .distantFuture)
        return (data, error)
    }
}
