//
//  Copyright © Nomasystems S.L.. All rights reserved.
//

import Foundation

public final class APIClient {
    private let urlSession: URLSession
    let baseUrl: URL

    init(baseUrl: URL) {
        let config: URLSessionConfiguration = {
            let config = URLSessionConfiguration.default
            config.httpShouldSetCookies = false
            config.httpCookieAcceptPolicy = .never
            return config
        }()
        self.urlSession = URLSession(configuration: config)
        self.baseUrl = baseUrl
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

