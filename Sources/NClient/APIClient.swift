//
//  Copyright © Nomasystems S.L.. All rights reserved.
//

import Foundation

/// Minimal Swift API client based on async/await.
public final class APIClient: NSObject {
    private let baseUrl: URL
    private var urlSession: URLSession!

    /// Initializes and setups a  instance of `APIClient`.
    ///
    /// - Parameters:
    ///   - baseUrl: The client server base URL for the API requests.
    ///   - config: The URLSessionConfiguration to use. Default is `URLSessionConfiguration.default`.
    ///
    /// - Returns: An initialized `APIClient` instance.
    public init(baseUrl: URL,
                config: URLSessionConfiguration = URLSessionConfiguration.default) {
        self.baseUrl = baseUrl
        super.init()
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
}

public extension APIClient {

    /// Performs an asynchronous API request to the specified endpoint.
    ///
    /// - Parameters:
    ///   - endpoint: Endpoint to request which has to conform `Endpoint`.
    ///   - parameters: Specific endpoint parameters used in the request.
    ///   - requestBody: Instance of the same type specified in the endpoint request body or `.empty`.
    ///
    /// - Returns: A `Response` object containing the HTTP response and the deserialized response body.
    ///
    /// - Throws: An `APIError` error if the request fails or the response is invalid.
    ///
    /// - Note: This method is only available for endpoints that don't require authentication (`_EndpointAuthNone`).
    ///
    /// - Important: This method is async and should be called using `await` to wait for the response.
    func performEndpointRequest<E: Endpoint>(
        endpoint: E,
        parameters: E.Parameters,
        requestBody: E.RequestBody
    ) async throws -> Response<E.ResponseBody>
    where E.Auth: _EndpointAuthNone
    {
        let request = try endpoint.request(
            baseUrl: baseUrl,
            parameters: parameters,
            requestBody: requestBody
        )

        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = try checkHttpResponse(response)
        let responseBody = try endpoint.deserializeBody(data)

        return Response(http: httpResponse, body: responseBody)
    }
}

private extension APIClient {

    func checkHttpResponse(_ urlResponse: URLResponse?) throws -> HTTPURLResponse {
        guard let httpResponse = urlResponse as? HTTPURLResponse else { throw APIError.failed }

        switch httpResponse.statusCode {
        case 200...299: return httpResponse
        case 400...499: throw APIError.client
        case 500...599: throw APIError.server
        default: throw APIError.failed
        }
    }
}

extension APIClient: URLSessionDelegate {

    /// Why do we need to conform `URLSessionDelegate`?
    ///
    /// When app makes a request, sever will respond with credential demands. Following
    /// delegate method provides an answer to such demands. In this case is needed for
    /// passing the TLS (`Transport Layer Security`) validation.
    ///
    /// Further information:
    /// - https://developer.apple.com/documentation/foundation/url_loading_system/handling_an_authentication_challenge
    public func urlSession(_ session: URLSession,
                           didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        #if DEBUG
        let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
        completionHandler(URLSession.AuthChallengeDisposition.useCredential, credential)
        #endif
    }
}

