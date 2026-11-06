//
//  LensReceiver.swift
//  LensExample
//

import Foundation

/// A Lens destination inside the app, to show what Lens sends: it answers the requests to `url` itself, which Lens
/// posts with the shared URL session.
final class LensReceiver: URLProtocol {
    static let url = "https://receiver.lens-example.invalid/reports"

    /// Called on the main queue with every report received, as a JSON object.
    static var onReport: (([String: Any]) -> Void)?

    static func start() {
        URLProtocol.registerClass(LensReceiver.self)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.absoluteString == url
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let body = request.httpBody ?? request.httpBodyStream.map(Self.read) ?? Data()
        let reports = (try? JSONSerialization.jsonObject(with: body) as? [String: Any])?["reports"] as? [[String: Any]] ?? []
        DispatchQueue.main.async {
            reports.forEach { Self.onReport?($0) }
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: "HTTP/1.1", headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func read(_ stream: InputStream) -> Data {
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 16_384)
        stream.open()
        defer { stream.close() }
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            data.append(buffer, count: count)
        }
        return data
    }
}
