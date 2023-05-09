//
//  Copyright © Nomasystems S.L.. All rights reserved.
//

import Foundation

public final class APIClient: NSObject {
    private let baseUrl: URL
    private var urlSession: URLSession!

    init(baseUrl: URL,
         config: URLSessionConfiguration = URLSessionConfiguration.default) {
        self.baseUrl = baseUrl
        super.init()
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
}

extension APIClient {

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

