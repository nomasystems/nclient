//
//  Copyright © Nomasystems S.L.. All rights reserved.
//

import XCTest
@testable import NClient

final class APIClientTests: XCTestCase {

    var sut: APIClient!

    // MARK: - SetUp and tearDown methods

    override func setUp() {
        let config: URLSessionConfiguration = {
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MockURLProtocol.self]
            return config
        }()

        sut = APIClient(baseUrl: mockBaseUrl, config: config)
    }

    override func tearDown() {
        sut = nil
        MockURLProtocol.handlers.removeAll()
    }

    // MARK: - Test methods

    func testPerformEndpointRequest_WhenGivenSuccessfulResponse_ReturnSuccessAndData() async throws {
        // Arrange
        MockURLProtocol.handlers.add(
            match: { $0.url == mockEndpointURL },
            result: .success(
                .init(
                    statusCode: 200,
                    headers: [HTTP.HeaderName.contentType.rawValue: HTTP.MIMEType.json],
                    data: mockResponseData
                )
            )
        )
        // Act
        let response = try await sut.performEndpointRequest(
            endpoint: MockEndpointWithResponseBody(),
            parameters: .empty,
            requestBody: .empty
        )
        // Assert
        XCTAssertEqual(response.http.statusCode, 200)
        XCTAssertEqual(response.body.responseMessage, "Hello, world!")
    }
}

private struct MockEndpointWithResponseBody: Endpoint {
    typealias ResponseBody = MockResponseBody

    func url(parameters: Parameters) -> URLComponents {
        .init(path: mockPath)
    }
}
