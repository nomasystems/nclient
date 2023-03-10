//
//  Copyright © Nomasystems S.L.. All rights reserved.
//

import Foundation

/// Describes an HTTP API endpoint (method + path + parameters)
protocol Endpoint {
    associatedtype Parameters = Empty
    associatedtype RequestBody = Empty
    associatedtype ResponseBody = Empty
    associatedtype Auth: _EndpointAuth = EndpointAuth.None

    var method: HTTP.Method { get }
    func url(parameters: Parameters) -> URLComponents
    func serializeBody(_ body: RequestBody, into request: inout URLRequest) throws
    func deserializeBody(_ data: Data) throws -> ResponseBody
}

protocol _EndpointAuth {}
protocol _EndpointAuthNone: _EndpointAuth {}
protocol _EndpointAuthAccessToken: _EndpointAuth {}

enum EndpointAuth {
    enum None: _EndpointAuthNone {}
    enum UserSessionOptional: _EndpointAuthNone, _EndpointAuthAccessToken {}
    enum UserSessionRequired: _EndpointAuthAccessToken {}
}

extension Endpoint {
    var method: HTTP.Method { .GET }
}

// MARK: Request creation

extension Endpoint {
    func request(
        baseUrl: URL,
        parameters: Parameters,
        requestBody: RequestBody
    ) throws
        -> URLRequest
    {
        let urlComponents = url(parameters: parameters)
        guard let url = urlComponents.url(relativeTo: baseUrl) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url.absoluteURL)
        request.httpMethod = method.rawValue
        request.setHeader(.accept, value: HTTP.MIMEType.json)
        try serializeBody(requestBody, into: &request)
        
        return request
    }
}

// MARK: Serialize

extension Endpoint where RequestBody == Empty {
    func serializeBody(_ body: RequestBody, into request: inout URLRequest) throws {}
}

extension Endpoint where RequestBody: Encodable {
    func serializeBody(_ body: RequestBody, into request: inout URLRequest) throws {
        request.setHeader(.contentType, value: HTTP.MIMEType.json)
        let data = try JSONEncoder().encode(body)
        request.httpBody = data
    }
}

// MARK: Deserialize

extension Endpoint where ResponseBody == Empty {
    func deserializeBody(_ data: Data) throws -> ResponseBody {
        .empty
    }
}

extension Endpoint where ResponseBody: Decodable {
    func deserializeBody(_ data: Data) throws -> ResponseBody {
        if let responseBody: ResponseBody = try? JSONDecoder().decode(ResponseBody.self, from: data) {
            return responseBody
        } else {
            throw APIError.data
        }
    }
}
