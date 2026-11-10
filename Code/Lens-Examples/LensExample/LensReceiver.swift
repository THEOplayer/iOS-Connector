//
//  LensReceiver.swift
//  LensExample
//

import Foundation
import LensSDKDev

/// Lens posts its reports with the shared URL session; this handles some of them inside the app:
/// - the reports to `url`, a JSON destination, are shown in the app;
/// - the reports to the staging ingest go out only while `forwardsToStaging` is on, and are answered here otherwise;
/// - the reports to `extraUrl`, a destination of your own, go out, and their HTTP status is shown.
final class LensReceiver: URLProtocol {
    static let url = "https://receiver.lens-example.invalid/reports"
    static let stagingUrl = LensDev.developmentIngestUrl

    /// Called on the main queue with every report received, as a JSON object.
    static var onReport: (([String: Any]) -> Void)?
    /// Called on the main queue after every post to the staging ingest: the HTTP status when it was sent, -1 when it
    /// failed, nil when it was answered here.
    static var onStagingPost: ((_ status: Int?) -> Void)?
    /// Called on the main queue after every post to `extraUrl`: the HTTP status, -1 when it failed.
    static var onExtraPost: ((_ status: Int) -> Void)?

    private static let lock = NSLock()
    private static var _forwardsToStaging = false
    private static var _extraUrl: String?
    static var forwardsToStaging: Bool {
        get { lock.lock(); defer { lock.unlock() }; return _forwardsToStaging }
        set { lock.lock(); defer { lock.unlock() }; _forwardsToStaging = newValue }
    }
    static var extraUrl: String? {
        get { lock.lock(); defer { lock.unlock() }; return _extraUrl }
        set { lock.lock(); defer { lock.unlock() }; _extraUrl = newValue }
    }

    private static let forwardedKey = "LensExampleForwarded"
    private var forwarding: URLSessionDataTask?

    static func start() {
        URLProtocol.registerClass(LensReceiver.self)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        guard property(forKey: forwardedKey, in: request) == nil else { return false }
        return [url, stagingUrl, extraUrl].contains(request.url?.absoluteString)
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let body = request.httpBody ?? request.httpBodyStream.map(Self.read) ?? Data()
        let target = request.url?.absoluteString
        if target == Self.url {
            let reports = (try? JSONSerialization.jsonObject(with: body) as? [String: Any])?["reports"] as? [[String: Any]] ?? []
            DispatchQueue.main.async { reports.forEach { Self.onReport?($0) } }
            answerLocally()
        } else if target == Self.extraUrl {
            forward(body) { status in Self.onExtraPost?(status) }
        } else if Self.forwardsToStaging {
            forward(body) { status in Self.onStagingPost?(status) }
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

    /// Sends the request on, then calls `posted` on the main queue with the HTTP status, -1 when it failed.
    private func forward(_ body: Data, posted: @escaping (Int) -> Void) {
        let outgoing = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        // Replaces the body stream, which URLSession hands protocols instead of the body.
        outgoing.httpBody = body
        URLProtocol.setProperty(true, forKey: Self.forwardedKey, in: outgoing)
        forwarding = URLSession.shared.dataTask(with: outgoing as URLRequest) { [weak self] data, response, error in
            guard let self else { return }
            let status = (response as? HTTPURLResponse)?.statusCode
            DispatchQueue.main.async { posted(status ?? -1) }
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
