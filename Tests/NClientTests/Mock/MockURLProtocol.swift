//
//  Copyright © Nomasystems S.L.. All rights reserved.
//

import Foundation

struct UnexpectedRequestError: Error, CustomStringConvertible {
    let request: URLRequest

    var description: String {
        "Unexpected request: \(request)"
    }
}

// MARK: - Request Handler

/// Container for all the request handlers
final class Handlers {

    typealias RequestMatchFunc = (URLRequest) -> Bool
    typealias InspectFunc = (URLRequest) -> Void

    struct HTTPResponse {
        let statusCode: Int
        let headers: [String: String]
        let data: Data

        init(statusCode: Int,
             headers: [String: String] = [:],
             data: Data = Data()) {
            self.statusCode = statusCode
            self.headers = headers
            self.data = data
        }
    }
    
    fileprivate struct Handler {
        let match: RequestMatchFunc
        let inspect: InspectFunc?
        let result: Result<HTTPResponse, URLError>
    }

    private let lock = NSLock()
    private var handlers: [Handler] = []

    /// Add a request handler.
    func add(
        match: @escaping RequestMatchFunc,
        inspect: InspectFunc? = nil,
        result: Result<HTTPResponse, URLError>
    ) {
        lock.lock()
        defer {
            lock.unlock()
        }
        handlers.append(.init(match: match, inspect: inspect, result: result))
    }

    /// Remove all request handlers.
    ///
    /// Call from test `tearDown` to ensure handlers do not interfere with the next test.
    func removeAll() {
        lock.lock()
        defer {
            lock.unlock()
        }
        handlers.removeAll()
    }

    fileprivate func handler(request: URLRequest) -> Handler? {
        lock.lock()
        defer {
            lock.unlock()
        }
        return handlers.first(where: { $0.match(request) })
    }
}

// MARK: - URL Protocol

/// Mock URLProtocol that responds to all requests with configured mock responses.
///
/// Example usage:
/// ```swift
/// // Configure URLSession to use MockURLProtocol
/// let configuration = URLSessionConfiguration.default
/// configuration.protocolClasses = [MockURLProtocol.self]
/// let urlSession = URLSession(configuration: configuration)
///
/// // Setup request handlers
/// MockURLProtocol.handlers.add(
///     match: { $0.url == someUrl },
///     inspect: {
///         XCTAssertEqual($0.allHTTPHeaderFields["some-header"], "value")
///     }
///     result: .success(.init(statusCode: 200))
/// )
///
/// // Perform requests using urlSession
/// ```
final class MockURLProtocol: URLProtocol {

    static let handlers = Handlers()

    override public func startLoading() {
        guard let client else { return }

        guard let handler = Self.handlers.handler(request: request) else {
            client.urlProtocol(self, didFailWithError: UnexpectedRequestError(request: request))
            return
        }
        handler.inspect?(request)

        switch handler.result {
        case .success(let httpResponse):
            let httpUrlResponse = HTTPURLResponse(
                url: request.url!,
                statusCode: httpResponse.statusCode,
                httpVersion: "1.1",
                headerFields: httpResponse.headers
            )!
            client.urlProtocol(self, didReceive: httpUrlResponse, cacheStoragePolicy: .notAllowed)
            client.urlProtocol(self, didLoad: httpResponse.data)
            client.urlProtocolDidFinishLoading(self)
        case .failure(let error):
            client.urlProtocol(self, didFailWithError: error)
        }
    }

    override public func stopLoading() {}

    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override public class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canInit(with task: URLSessionTask) -> Bool {
        true
    }
}
