//
//  Copyright © Nomasystems S.L.. All rights reserved.
//

import Foundation

public protocol _EndpointAuth {}
public protocol _EndpointAuthNone: _EndpointAuth {}
public protocol _EndpointAuthAccessToken: _EndpointAuth {}

/// Aauthentication types for an endpoint.
public enum EndpointAuth {
    /// No authentication required.
    public enum None: _EndpointAuthNone {}

    /// Optional user session authentication.
    public enum UserSessionOptional: _EndpointAuthNone, _EndpointAuthAccessToken {}

    /// Required user session authentication.
    public enum UserSessionRequired: _EndpointAuthAccessToken {}
}

/// Describes an HTTP API endpoint (method + path + parameters)
public protocol Endpoint {
    associatedtype Parameters = Empty
    associatedtype RequestBody = Empty
    associatedtype ResponseBody = Empty
    associatedtype Auth: _EndpointAuth = EndpointAuth.None

    /// The HTTP method of the endpoint.
    var method: HTTP.Method { get }

    var contentType: HTTP.MIMEType { get }

    /// Constructs the URL components for the endpoint given the parameters.
    func url(parameters: Parameters) -> URLComponents

    /// Serializes the request body into the given URLRequest.
    func serializeBody(_ body: RequestBody, into request: inout URLRequest) throws

    /// Deserializes the response body from the received data.
    func deserializeBody(_ data: Data) throws -> ResponseBody
}

public extension Endpoint {
    /// The default HTTP method for the endpoint is `GET`.
    var method: HTTP.Method { .GET }

    /// The default Content-Type  for the endpoint is `application/json`.
    var contentType: HTTP.MIMEType { .json }
}

// MARK: Request creation

public extension Endpoint {

    /// Creates a URLRequest for the endpoint with the provided parameters and request body.
    ///
    /// - Parameters:
    ///   - baseUrl: The base URL for the endpoint.
    ///   - parameters: The parameters associated with the request.
    ///   - requestBody: The request body associated with the request.
    ///
    /// - Returns: A URLRequest object representing the request.
    ///
    /// - Throws: An error if the URL construction fails or if there is an error serializing the request body.
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
        request.setHeader(.accept, value: HTTP.MIMEType.json.rawValue)
        try serializeBody(requestBody, into: &request)
        
        return request
    }
}

// MARK: Serialize

public extension Endpoint where RequestBody == Empty {
    /// No implementation in case of empty request body.
    func serializeBody(_ body: RequestBody, into request: inout URLRequest) throws {}
}

public extension Endpoint where RequestBody: Encodable {
    /// Serializes an encodable request body as JSON.
    func serializeBody(_ body: RequestBody, into request: inout URLRequest) throws {
        request.setHeader(.contentType, value: contentType.rawValue)
        let data = try JSONEncoder().encode(body)
        request.httpBody = data
    }
}

public extension Endpoint where RequestBody == Data {
    /// Bypass serialization if request body is already of Data type
    func serializeBody(_ body: RequestBody, into request: inout URLRequest) throws {
        request.setHeader(.contentType, value: contentType.rawValue)
        request.httpBody = body
    }
}

// MARK: Deserialize

public extension Endpoint where ResponseBody == Empty {
    /// Returns `.empty` so there is no expected response.
    func deserializeBody(_ data: Data) throws -> ResponseBody {
        .empty
    }
}

public extension Endpoint where ResponseBody: Decodable {
    /// Deserializes a decodable response body from the received data.
    func deserializeBody(_ data: Data) throws -> ResponseBody {
        if let responseBody: ResponseBody = try? JSONDecoder().decode(ResponseBody.self, from: data) {
            return responseBody
        } else {
            throw APIError.data
        }
    }
}
