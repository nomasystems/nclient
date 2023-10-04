//
//  Copyright © Nomasystems S.L.. All rights reserved.
//

import XCTest
@testable import NClient

final class EndpointTests: XCTestCase {

    // MARK: Endpoint

    func testEndpoint() throws {
        let endpoint = MockEndpoint()
        let request = try endpoint.request(
            baseUrl: mockBaseUrl,
            parameters: .empty,
            requestBody: .empty
        )

        XCTAssertEqual(request.url?.absoluteString, "https://example.com/path")
        XCTAssertEqual(request.httpMethod, HTTP.Method.GET.rawValue)

        XCTAssertEqual(request.value(forHTTPHeaderField: HTTP.HeaderName.accept.rawValue), HTTP.MIMEType.json.rawValue)
        XCTAssertNil(request.value(forHTTPHeaderField: HTTP.HeaderName.contentType.rawValue))

        XCTAssertNil(request.httpBody)
    }

    func testEndpointWithParameters() throws {
        let endpoint = MockEndpointWithParameters()
        let request = try endpoint.request(
            baseUrl: mockBaseUrl,
            parameters: mockParameters,
            requestBody: .empty
        )

        XCTAssertEqual(request.url?.absoluteString, "https://example.com/path/search?name=John&age=30")
    }

    func testEndpointWithRequestBody() throws {
        let endpoint = MockEndpointWithRequestBody()
        let request = try endpoint.request(
            baseUrl: mockBaseUrl,
            parameters: .empty,
            requestBody: mockRequestBody
        )

        XCTAssertEqual(request.url?.absoluteString, "https://example.com/path")
        XCTAssertEqual(request.httpMethod, HTTP.Method.POST.rawValue)

        XCTAssertEqual(request.value(forHTTPHeaderField: HTTP.HeaderName.accept.rawValue), HTTP.MIMEType.json.rawValue)
        XCTAssertEqual(request.value(forHTTPHeaderField: HTTP.HeaderName.contentType.rawValue), HTTP.MIMEType.json.rawValue)

        let bodyData = try JSONEncoder().encode(mockRequestBody)
        XCTAssertNotNil(request.httpBody)
        XCTAssertEqual(request.httpBody, bodyData)
    }

    func testEndpointWithRawRequestBody() throws {
        let endpoint = MockEndpointWithRawResponseBody()
        let request = try endpoint.request(
            baseUrl: mockBaseUrl,
            parameters: .empty,
            requestBody: try XCTUnwrap(mockMessage.data(using: .utf8))
        )

        XCTAssertEqual(request.url?.absoluteString, "https://example.com/path")
        XCTAssertEqual(request.httpMethod, HTTP.Method.POST.rawValue)

        XCTAssertEqual(request.value(forHTTPHeaderField: HTTP.HeaderName.accept.rawValue), HTTP.MIMEType.json.rawValue)
        XCTAssertEqual(request.value(forHTTPHeaderField: HTTP.HeaderName.contentType.rawValue), HTTP.MIMEType.mp4.rawValue)

        let requestBody = try XCTUnwrap(request.httpBody)
        XCTAssertEqual(String(data: requestBody, encoding: .utf8), mockMessage)
    }

    // MARK: Deserialize
    
    func testDeserializeEmptyBody() throws {
        let endpoint = MockEndpoint()

        XCTAssertNoThrow(try endpoint.deserializeBody(mockResponseData))

        let responseBody = try endpoint.deserializeBody(mockResponseData)
        XCTAssertNotNil(responseBody)
    }

    func testDeserializeBody() throws {
        let endpoint = MockEndpointWithResponseBody()

        XCTAssertNoThrow(try endpoint.deserializeBody(mockResponseData))

        let responseBody = try endpoint.deserializeBody(mockResponseData)
        XCTAssertNotNil(responseBody)
        XCTAssertEqual(responseBody.responseMessage, "Hello, world!")
    }

}

let mockBaseUrl = URL(string: "https://example.com")!
let mockPath = "path"
let mockEndpointURL = mockBaseUrl.appendingPathComponent(mockPath)

struct MockParameters {
    let name: String
    let age: Int
}

struct MockRequestBody: Encodable {
    let message: String
}

struct MockResponseBody: Decodable {
    let responseMessage: String
}

let mockMessage = "Hello, world!"
let mockParameters = MockParameters(name: "John", age: 30)
let mockRequestBody = MockRequestBody(message: mockMessage)
let mockResponseData = "{\"responseMessage\":\"\(mockMessage)\"}".data(using: .utf8)!

private struct MockEndpoint: Endpoint {
    func url(parameters: Parameters) -> URLComponents {
        .init(path: mockPath)
    }
}

private struct MockEndpointWithParameters: Endpoint {
    typealias Parameters = MockParameters

    func url(parameters: Parameters) -> URLComponents {
        .init(
            path: mockPath + "/search",
            queryItems: [
                .init(name: "name", value: parameters.name),
                .init(name: "age", value: String(parameters.age))
            ]
        )
    }
}

private struct MockEndpointWithRequestBody: Endpoint {
    typealias RequestBody = MockRequestBody

    var method: HTTP.Method {
        .POST
    }

    func url(parameters: Parameters) -> URLComponents {
        .init(path: mockPath)
    }
}

private struct MockEndpointWithResponseBody: Endpoint {
    typealias ResponseBody = MockResponseBody

    func url(parameters: Parameters) -> URLComponents {
        .init(path: mockPath)
    }
}

private struct MockEndpointWithRawResponseBody: Endpoint {
    typealias RequestBody = Data

    var method: HTTP.Method {
        .POST
    }

    var contentType: HTTP.MIMEType {
        .mp4
    }

    func url(parameters: Parameters) -> URLComponents {
        .init(path: mockPath)
    }
}
