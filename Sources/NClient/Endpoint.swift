//
//  Copyright © Nomasystems S.L.. All rights reserved.
//

import Foundation

/// Describes an HTTP API endpoint (method + path + parameters)
public protocol Endpoint {
    associatedtype Parameters = Empty
    associatedtype RequestBody = Empty
    associatedtype ResponseBody = Empty
    associatedtype Auth: _EndpointAuth = EndpointAuth.None

    var method: HTTP.Method { get }
    func url(parameters: Parameters) -> URLComponents
    func serializeBody(_ body: RequestBody, into request: inout URLRequest) throws
    func deserializeBody(_ data: Data) throws -> ResponseBody
}

public protocol _EndpointAuth {}
public protocol _EndpointAuthNone: _EndpointAuth {}
public protocol _EndpointAuthAccessToken: _EndpointAuth {}

public enum EndpointAuth {
    public enum None: _EndpointAuthNone {}
    public enum UserSessionOptional: _EndpointAuthNone, _EndpointAuthAccessToken {}
    public enum UserSessionRequired: _EndpointAuthAccessToken {}
}

public extension Endpoint {
    var method: HTTP.Method { .GET }
}

// MARK: Request creation

public extension Endpoint {
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

public extension Endpoint where RequestBody == Empty {
    func serializeBody(_ body: RequestBody, into request: inout URLRequest) throws {}
}

public extension Endpoint where RequestBody: Encodable {
    func serializeBody(_ body: RequestBody, into request: inout URLRequest) throws {
        request.setHeader(.contentType, value: HTTP.MIMEType.json)
        let data = try JSONEncoder().encode(body)
        request.httpBody = data
    }
}

// MARK: Deserialize

public extension Endpoint where ResponseBody == Empty {
    func deserializeBody(_ data: Data) throws -> ResponseBody {
        .empty
    }
}

public extension Endpoint where ResponseBody: Decodable {
    func deserializeBody(_ data: Data) throws -> ResponseBody {
        if let responseBody: ResponseBody = try? JSONDecoder().decode(ResponseBody.self, from: data) {
            return responseBody
        } else {
            throw APIError.data
        }
    }
}
