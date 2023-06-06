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
            requestBody: .empty
        )

        XCTAssertEqual(request.url?.absoluteString, "https://example.com/path")
        XCTAssertEqual(request.httpMethod, HTTP.Method.GET.rawValue)

        XCTAssertEqual(request.value(forHTTPHeaderField: HTTP.HeaderName.accept.rawValue), HTTP.MIMEType.json)
        XCTAssertNil(request.value(forHTTPHeaderField: HTTP.HeaderName.contentType.rawValue))

        XCTAssertNil(request.httpBody)
    }

    func testEndpointWithParameters() throws {
        let endpoint = MockEndpointWithParameters(name: mockParameters.name,
                                                  age: mockParameters.age)
        let request = try endpoint.request(
            baseUrl: mockBaseUrl,
            requestBody: .empty
        )

        XCTAssertEqual(request.url?.absoluteString, "https://example.com/path/search?name=John&age=30")
    }

    func testEndpointWithRequestBody() throws {
        let endpoint = MockEndpointWithRequestBody()
        let request = try endpoint.request(
            baseUrl: mockBaseUrl,
            requestBody: mockRequestBody
        )

        XCTAssertEqual(request.url?.absoluteString, "https://example.com/path")
        XCTAssertEqual(request.httpMethod, HTTP.Method.POST.rawValue)

        XCTAssertEqual(request.value(forHTTPHeaderField: HTTP.HeaderName.accept.rawValue), HTTP.MIMEType.json)
        XCTAssertEqual(request.value(forHTTPHeaderField: HTTP.HeaderName.contentType.rawValue), HTTP.MIMEType.json)

        let bodyData = try JSONEncoder().encode(mockRequestBody)
        XCTAssertNotNil(request.httpBody)
        XCTAssertEqual(request.httpBody, bodyData)
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
    let path: String = mockPath
}

private struct MockEndpointWithParameters: Endpoint {

    let name: String
    let age: Int

    var path: String { mockPath + "/search" }

    var queryItems: [URLQueryItem] {
        [
            .init(name: "name", value: name),
            .init(name: "age", value: String(age))
        ]
    }
}

private struct MockEndpointWithRequestBody: Endpoint {

    typealias RequestBody = MockRequestBody

    var path: String { mockPath }

    var method: HTTP.Method {
        .POST
    }
}

private struct MockEndpointWithResponseBody: Endpoint {

    typealias ResponseBody = MockResponseBody

    var path: String { mockPath }
}
