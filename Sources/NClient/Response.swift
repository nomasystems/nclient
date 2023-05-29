//
//  Copyright © Nomasystems S.L.. All rights reserved.
//

import Foundation

/// Represents an API response containing an HTTP Response and its body.
///
/// Used by `APIClient` to encapsulate the response received from an API call.
///
/// - Note: The `Body` type can be any type, depending on the specific API response structure.
public struct Response<Body> {
    
    /// An instance of `HTTPURLResponse` representing the HTTP response received.
    public let http: HTTPURLResponse

    /// The response body
    public let body: Body
}
