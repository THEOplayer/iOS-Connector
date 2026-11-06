//
//  LensReceiver.swift
//  LensExample
//

import Foundation
import LensSDKDev

/// Lens posts its reports with the shared URL session; this answers some of them inside the app:
/// - the reports to `url`, a JSON destination, are shown in the app;
/// - the reports to the staging ingest go out only while `forwardsToStaging` is on, and are answered here otherwise.
final class LensReceiver: URLProtocol {
    static let url = "https://receiver.lens-example.invalid/reports"
    static let stagingUrl = LensDev.developmentIngestUrl

    /// Called on the main queue with every report received, as a JSON object.
    static var onReport: (([String: Any]) -> Void)?
    /// Called on the main queue after every post to the staging ingest: the HTTP status when it was sent, nil when it
    /// was answered here.
    static var onStagingPost: ((_ status: Int?) -> Void)?

    private static let lock = NSLock()
    private static var _forwardsToStaging = false
    static var forwardsToStaging: Bool {
        get { lock.lock(); defer { lock.unlock() }; return _forwardsToStaging }
        set { lock.lock(); defer { lock.unlock() }; _forwardsToStaging = newValue }
    }

    private static let forwardedKey = "LensExampleForwarded"
    private var forwarding: URLSessionDataTask?

    static func start() {
        URLProtocol.registerClass(LensReceiver.self)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        guard property(forKey: forwardedKey, in: request) == nil else { return false }
        return [url, stagingUrl].contains(request.url?.absoluteString)
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let body = request.httpBody ?? request.httpBodyStream.map(Self.read) ?? Data()
        if request.url?.absoluteString == Self.url {
            let reports = (try? JSONSerialization.jsonObject(with: body) as? [String: Any])?["reports"] as? [[String: Any]] ?? []
            DispatchQueue.main.async { reports.forEach { Self.onReport?($0) } }
            answerLocally()
        } else if Self.forwardsToStaging {
            forward(body)
        } else {
            DispatchQueue.main.async { Self.onStagingPost?(nil) }
            answerLocally()
        }
    }

    override func stopLoading() {
        forwarding?.cancel()
    }

    private func answerLocally() {
        let response = HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: "HTTP/1.1", headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocolDidFinishLoading(self)
    }

    private func forward(_ body: Data) {
        let outgoing = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        outgoing.httpBody = body
        outgoing.httpBodyStream = nil
        URLProtocol.setProperty(true, forKey: Self.forwardedKey, in: outgoing)
        forwarding = URLSession.shared.dataTask(with: outgoing as URLRequest) { [weak self] data, response, error in
            guard let self else { return }
            let status = (response as? HTTPURLResponse)?.statusCode
            DispatchQueue.main.async { Self.onStagingPost?(status ?? -1) }
            if let response {
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                data.map { self.client?.urlProtocol(self, didLoad: $0) }
                self.client?.urlProtocolDidFinishLoading(self)
            } else {
                self.client?.urlProtocol(self, didFailWithError: error ?? URLError(.unknown))
            }
        }
        forwarding?.resume()
    }

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
